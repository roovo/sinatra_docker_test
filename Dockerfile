FROM howareyou/ruby:2.0.0-p247

ADD ./ /var/apps/sinatra_docker_test

RUN \
  . /.profile ;\
  rm -fr /var/apps/sinatra_docker_test/.git ;\
  cd /var/apps/sinatra_docker_test ;\
  bundle install --local ;\
# END RUN

WORKDIR /var/apps/sinatra_docker_test

ENTRYPOINT ["bin/run"]

EXPOSE 8000
