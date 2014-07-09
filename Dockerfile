FROM debian:7.4
MAINTAINER Brad Chapman "https://github.com/chapmanb"

# Setup a base system 
RUN apt-get update && apt-get install -y build-essential zlib1g-dev wget curl python-setuptools git python-pip python-dev sudo
RUN pip install fabric
RUN pip install fabtools
RUN pip install jinja2

# passwordless ssh
RUN apt-get install -y ssh
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
RUN service ssh restart
RUN ssh-keygen -f /root/.ssh/id_rsa -P ''
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
RUN ssh-keyscan -H localhost >> /root/.ssh/known_hosts
RUN ln -s /root/.ssh /.ssh

# Deploy richard
RUN git clone https://github.com/codersquid/richard-deploy.git
RUN echo "admins = [('dag', 'dag@bioteam.net'), ('brad', 'chapmanb@50mail.com'), ('carl', 'carl@nextdayvideo.com', ), ('sheila', 'sheila@codersquid.com')]" > richard-deploy/secrets.py
RUN sed -i 's/SITE_NAME = "rt1"/SITE_NAME = "vid"/g' richard-deploy/fabfile.py
RUN sed -i "s/SERVER_NAME='richard.test1.nextdayvideo.com'/SERVER_NAME='localhost'/g" richard-deploy/fabfile.py
RUN sed -i "s/^env.hosts/#env.hosts/g" richard-deploy/fabfile.py
RUN sed -i "s/require.postgres.server()/require.postgres.server(); sudo('service postgresql start')/g" richard-deploy/fabfile.py
RUN sed -i "s/supervisor.update_config()/sudo('service supervisor start'); supervisor.update_config(); sudo('service supervisor stop')/g" richard-deploy/fabfile.py
RUN ssh-keyscan -H localhost >> /root/.ssh/known_hosts && service ssh start & cd richard-deploy && fab -H localhost provision
RUN supervisorctl stop vid
CMD service postgresql start && service nginx start && service supervisor start && supervisorctl start vid && /bin/bash