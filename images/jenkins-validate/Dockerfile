FROM jenkins/jenkins:lts
ENV JENKINS_USER admin
ENV JENKINS_PASS admin

# Skip initial setup
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Add JCasC
COPY casc.yaml /var/jenkins_home/jcasc-confs/casc.yaml
ENV CASC_JENKINS_CONFIG /var/jenkins_home/jcasc-conf

