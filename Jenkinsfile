pipeline {
    agent any
    environment {
        DOCKER_REPO = 'achrefmessai/dockerapp1'  // Remplacer par votre repo Docker Hub
        SKIP_TLS_VERIFY = 'true'                // Mettre à 'true' si problème TLS (dev only)
    }

    stages {
        stage('Préparer le tag') {
            steps {
                script {
                    def shortSha = 'nocmt'
                    try {
                        shortSha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    } catch (err) {
                        echo "Impossible d'obtenir le SHA git: ${err}"
                    }
                    env.IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}-${shortSha}"
                    env.FULL_IMAGE = "${env.DOCKER_REPO}:${env.IMAGE_TAG}"
                    echo "Image tag: ${env.FULL_IMAGE}"
                }
            }
        }

        stage('Construire l\'image Docker') {
            steps {
                script {
                    sh "docker build -t ${env.FULL_IMAGE} ."
                }
            }
        }

        stage('Pousser l\'image Docker') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockercred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh 'echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin'
                    sh "docker push ${env.FULL_IMAGE}"
                    sh 'docker logout'
                }
            }
        }

        stage('Déployer sur Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                        script {
                            // Mise à jour de l'image dans le manifest
                            sh "sed -E 's|(image: ).*|\\1${env.FULL_IMAGE}|' deployment.yaml > deployment-merged.yaml || true"
                            sh "if [ ! -s deployment-merged.yaml ]; then cp deployment.yaml deployment-merged.yaml; fi"

                            // Patch du kubeconfig pour Jenkins (Docker Desktop)
                            sh '''
                            # Remplace 127.0.0.1 par host.docker.internal (accès depuis le conteneur Jenkins)
                            sed -E 's|127\\.0\\.0\\.1|host.docker.internal|g' "$KUBECONFIG_FILE" > "$KUBECONFIG_FILE.tmp" || cp "$KUBECONFIG_FILE" "$KUBECONFIG_FILE.tmp"

                            # Si SKIP_TLS_VERIFY=true → supprimer les certificats et ajouter "insecure-skip-tls-verify"
                            if [ "${SKIP_TLS_VERIFY}" = "true" ]; then
                              echo "⚠️  SKIP_TLS_VERIFY activé : suppression du certificat et ajout de insecure-skip-tls-verify"
                              awk '!/certificate-authority-data:/' "$KUBECONFIG_FILE.tmp" > "$KUBECONFIG_FILE.clean"
                              awk '/clusters:/{print; print "  - cluster:"; print "      insecure-skip-tls-verify: true"; next}1' "$KUBECONFIG_FILE.clean" > "$KUBECONFIG_FILE.tmp"
                            fi

                            mv "$KUBECONFIG_FILE.tmp" "$KUBECONFIG_FILE"
                            chmod 600 "$KUBECONFIG_FILE" || true

                            echo "Using kubeconfig server (after patch):"
                            grep -n "server:" "$KUBECONFIG_FILE" || true

                            # Appliquer les manifests
                            kubectl --kubeconfig="$KUBECONFIG_FILE" apply -f deployment-merged.yaml
                            kubectl --kubeconfig="$KUBECONFIG_FILE" apply -f service.yaml
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline terminé avec succès. Image déployée : ${env.FULL_IMAGE}"
        }
        failure {
            echo "❌ Pipeline échoué. Vérifiez les logs de Jenkins."
        }
    }
}
