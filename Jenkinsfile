pipeline {
	agent any
		environment {
			DOCKER_REPO = 'achrefmessai/dockerapp1' // remplacer par votre repo Docker Hub, ex: myuser/mon-app
		}
	stages {
		stage('Cloner le dépôt') {
			steps {
				// Si Jenkins est configuré pour récupérer depuis SCM, ce step peut être omis
				git url: 'https://github.com/achrefmessai01/dockerapp1.git'
			}
		}

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
							sh "kubectl apply -f deployment-merged.yaml"
							sh "kubectl apply -f service.yaml"
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

