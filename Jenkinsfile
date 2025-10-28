pipeline {
	agent any
		environment {
			DOCKER_REPO = 'achrefmessai/dockerapp1' // remplacer par votre repo Docker Hub, ex: myuser/mon-app
			// Si vous faites face à des erreurs TLS pendant les tests, mettre à 'true' (dev only)
			SKIP_TLS_VERIFY = 'false'
		}
	stages {
		// Checkout is handled by the Pipeline "Pipeline script from SCM" configuration;
		// explicit git checkout stage removed to avoid double-checkout and branch mismatches.

		stage('Préparer le tag') {
			steps {
				script {
					// Calcule un tag unique: BUILD_NUMBER + court SHA git si présent
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
				// Attendez-vous à avoir ajouté un credential de type "Secret file" nommé 'kubeconfig' dans Jenkins
				withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
					withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
						script {
							// Remplace l'image dans le manifest, crée deployment-merged.yaml puis applique
							sh "sed -E 's|(image: ).*|\\1${env.FULL_IMAGE}|' deployment.yaml > deployment-merged.yaml || true"
							// Si sed n'a pas créé le fichier (par ex. Windows), on retente une simple substitution
							sh "if [ ! -s deployment-merged.yaml ]; then cp deployment.yaml deployment-merged.yaml; fi"
							// Patch kubeconfig pour que l'API server soit joignable depuis le conteneur Jenkins
							// Remplace 127.0.0.1 par host.docker.internal (Docker Desktop). Pour testing TLS, SKIP_TLS_VERIFY peut être activé via l'environnement.
							sh '''
							# Remplace 127.0.0.1 par host.docker.internal si présent
							sed -E "s|(server: )https?://127\\.0\\.0\\.1(:[0-9]+)?|\1https://host.docker.internal\2|" "$KUBECONFIG_FILE" > "$KUBECONFIG_FILE.tmp" || cp "$KUBECONFIG_FILE" "$KUBECONFIG_FILE.tmp"
							# Si nécessaire, ajouter insecure-skip-tls-verify (dev only) pour éviter les erreurs TLS liées au SAN
							if [ "${SKIP_TLS_VERIFY}" = "true" ]; then
								awk '/certificate-authority-data:/{print; print "    insecure-skip-tls-verify: true"; next}1' "$KUBECONFIG_FILE.tmp" > "$KUBECONFIG_FILE.patched" && mv "$KUBECONFIG_FILE.patched" "$KUBECONFIG_FILE.tmp"
							fi
							mv "$KUBECONFIG_FILE.tmp" "$KUBECONFIG_FILE"
							chmod 600 "$KUBECONFIG_FILE" || true
						
echo "Using kubeconfig server:"
							grep "server:" "$KUBECONFIG_FILE" || true
							# Applique les manifests en explicitant le kubeconfig (sécurise contre les problèmes d'environnement)
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
			echo "Pipeline terminé avec succès. Image: ${env.FULL_IMAGE}"
		}
		failure {
			echo "Pipeline échoué. Vérifier les logs de Jenkins."
		}
	}
}

