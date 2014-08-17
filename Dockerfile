FROM phusion/baseimage:latest
MAINTAINER Bart Teeuwisse <bart@thecodemill.biz>

# Set to the locale to UTF-8 so that the default detabase encoding is UTF-8 instead of ASCII.
RUN update-locale LANG=en_US.UTF-8

# Install postgres 9.3
RUN apt-get update
RUN apt-get install -y postgresql postgresql-contrib

# Make bash the default shell.
ENV SHELL /bin/bash

# Disable the ssh server
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Setup `postgres`'s home for interactive shells.
RUN mkdir /home/postgres
RUN chown postgres:postgres /home/postgres

# Run the rest of the commands as the `postgres` user created by the `postgres-9.3` package 
# when it was `apt-get installed`
USER postgres
ENV HOME /home/postgres
ENV PATH /usr/lib/postgresql/9.3/bin:$PATH
ENV PGDATA /var/lib/postgresql/9.3/main

# Create a PostgreSQL role named `docker` with `docker` as the password and
# then create a database `docker` owned by the `docker` role.
# Note: here we use `&&\` to run commands one after the other - the `\`
# allows the RUN command to span multiple lines.
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible. 
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql/9.3/main"]

# Set the default command to run when starting the container
CMD ["postgres", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]
