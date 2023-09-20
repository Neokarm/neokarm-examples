sonar:
	sonar-scanner -Dsonar.projectKey=Harelfel_neokarm-examples \
		-Dsonar.sources=. \
		-Dsonar.pullrequest.key=${PULL_REQUEST_ID} \
		-Dsonar.pullrequest.branch=${PULL_REQUEST_ID} \
		-Dsonar.host.url=https://sonarcloud.io \
		-Dsonar.login=20636367fc6c0690af02dfdc5dfc9b11d6d475c3
# =========================================================================