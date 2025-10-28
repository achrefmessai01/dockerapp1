pipeline {
    agent any

    environment {
        DOCKER_REPO = 'achrefmessai/dockerapp1'        // Ton repo Docker Hub
        IMAGE_TAG = "${env.BUILD_NUMBER}"              // Numéro du build
        FULL_IMAGE = "${DOCKER_REPO}:${IMAGE_TAG}"     // Image complète
        HELM_CHART_PATH = './mon-app'                  // Chemin du chart Helm
    }

    stages {

        /*********************
         * 1️⃣ Installation locale de Helm (sans sudo)
         *********************/
        stage('Installer Helm') {
            steps {
                sh '''
                    if ! command -v helm >/dev/null 2>&1; then
                        echo "🛠️ Téléchargement et installation locale de Helm..."
                        mkdir -p $HOME/bin
                        curl -fsSL https://get.helm.sh/helm-v3.14.2-linux-amd64.tar.gz -o helm.tar.gz
                        tar -zxvf helm.tar.gz > /dev/null
                        mv linux-amd64/helm $HOME/bin/helm
                        export PATH=$HOME/bin:$PATH
                        echo "✅ Helm installé localement dans $HOME/bin"
                    else
                        echo "✅ Helm déjà installé."
                    fi
                    export PATH=$HOME/bin:$PATH
                    helm version || echo "⚠️ Helm non détecté dans le PATH"
                '''
            }
        }

        /*********************
         * 2️⃣ Préparation du code
         *********************/
        stage('Préparer le code') {
            steps {
                checkout scm
                echo "✅ Dépôt cloné avec succès."
            }
        }

        /*********************
         * 3️⃣ Construction de l'image Docker
         *********************/
        stage('Construire l\'image Docker') {
            steps {
                script {
                    echo "🏗️ Construction de l'image Docker : ${FULL_IMAGE}"
                    sh "docker build -t ${FULL_IMAGE} ."
                }
            }
        }

        /*********************
         * 4️⃣ Push de l'image sur Docker Hub
         *********************/
        stage('Pousser l\'image Docker') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockercred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        echo "🚀 Connexion à Docker Hub..."
                        sh '''
                            echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                            docker push ${FULL_IMAGE}
                            docker logout
                        '''
                    }
                }
            }
        }

        /*********************
         * 5️⃣ Déploiement sur Kubernetes via Helm
         *********************/
        stage('Déployer avec Helm') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    withEnv(["KUBECONFIG=${KUBECONFIG_FILE}", "PATH=$HOME/bin:$PATH"]) {
                        script {
                            echo "📦 Déploiement de ${FULL_IMAGE} sur Kubernetes avec Helm..."

                            sh """
                                helm upgrade --install mon-app ${HELM_CHART_PATH} \
                                    --set image.repository=${DOCKER_REPO} \
                                    --set image.tag=${IMAGE_TAG} \
                                    --set image.pullPolicy=IfNotPresent \
                                    --namespace default \
                                    --create-namespace

                                echo "🔍 Vérification du déploiement..."
                                helm status mon-app --namespace default || true
                            """
                        }
                    }
                }
            }
        }
    }

    /*********************
     * 6️⃣ Résultats finaux
     *********************/
    post {
        success {
            echo "✅ Pipeline terminé avec succès !"
            echo "Image déployée : ${FULL_IMAGE}"
        }
        failure {
            echo "❌ Pipeline échoué. Consulte les logs Jenkins pour plus de détails."
        }
    }
}
