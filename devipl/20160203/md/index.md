## Update GitLab in docker

---

事の発端はこんな会話から…

---

先輩：「GitLabのバージョン上げたいけど、設定がな～」  
自分：「それdockerなら簡単にできますよ」  
先輩：「お～、それじゃあお願いしていいかな？」  
自分：「はい、よろこんで！！」

---

というわけで、今回は7.12.2から8.3.0へのバージョンアップになります。
ただ、新規にGitLab in dockerを行う場合も、この方法で作成できます。

---

### Environment

* HostOS: CentOS release 6.5
* GuestOS: Ubuntu 14.04 LTS
* docker version: 1.9.1

--

![env01](image/env01.png)

--

![env02](image/env02.png)

--

![env03](image/env03.png)

---

### Important point

--

7.12.2のバックアップデータを直接8.3.0でリストアしようとしても、互換性の問題があるため、上手くいきません。  
そこで次のような順序でバージョンをあげます。

_**7.12.2 => 7.14.3 => 8.1.4 => 8.2.0 => 8.3.0-1**_

※[Upgrade fails from 7.8.1 to 8.2.0 #504](https://github.com/sameersbn/docker-gitlab/issues/504)

---

### Work

※[sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab)

---

#### docker pull 

先に必要なdockerイメージをpullしておきます。  

```shell-session
$ sudo docker pull [REPOSITORY]:[TAG]
$ sudo docker images
REPOSITORY             TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
sameersbn/gitlab       8.3.0-1             daeb1d65a71d        3 days ago          682.3 MB
sameersbn/gitlab       8.2.0               4f8184d55f41        5 weeks ago         675.3 MB
sameersbn/redis        latest              f69db76d2fa8        5 weeks ago         196.5 MB
sameersbn/postgresql   9.4-8               81c68746a367        5 weeks ago         231.2 MB
sameersbn/gitlab       8.1.4               f819f70c97f3        6 weeks ago         678.9 MB
sameersbn/gitlab       7.14.3              43e1dcc0390f        3 months ago        631.6 MB
sameersbn/gitlab       7.12.2              31072a65dc42        5 months ago        627.5 MB
```

---

#### docker-compose.yml

※[docker-gitlab/docker-compose.yml](https://github.com/sameersbn/docker-gitlab/blob/master/docker-compose.yml)  
※[sameersbn/docker-gitlab#configuration](https://github.com/sameersbn/docker-gitlab#configuration)

--

```yaml
postgresql:
  restart: always
  image: sameersbn/postgresql:9.4-8
  environment:
    - DB_USER=xxxx
    - DB_PASS=xxxx
    - DB_NAME=xxxx
  volumes:
    - /home/vagrant/docker-gitlab/gitlab-data/postgresql:/var/lib/postgresql
gitlab:
  restart: always
  image: sameersbn/gitlab:7.12.2
  links:
    - redis:redisio
    - postgresql:postgresql
  ports:
    - "xxxx:80"
    - "xxxx:22"
  environment:
    - TZ=Asia/Tokyo
    - GITLAB_TIMEZONE=Tokyo
    - GITLAB_SECRETS_DB_KEY_BASE=xxxxxxxxxxxxxxxxxxxxxxxxx
    - GITLAB_HOST=xxx.xxx.xxx.xxx
    - GITLAB_PORT=xxxx
    - GITLAB_SSH_PORT=xxxx
    - GITLAB_NOTIFY_ON_BROKEN_BUILDS=true
    - GITLAB_NOTIFY_PUSHER=false
    - GITLAB_EMAIL=xxxx@gmail.com
    - GITLAB_EMAIL_REPLY_TO=xxxx@gmail.com
    - GITLAB_INCOMING_EMAIL_ADDRESS=xxxx@gmail.com
    - GITLAB_BACKUP_SCHEDULE=daily
    - GITLAB_BACKUP_EXPIRY=604800
    - GITLAB_BACKUP_TIME=01:00
    - SMTP_ENABLED=true
    - SMTP_DOMAIN=www.gmail.com
    - SMTP_HOST=smtp.gmail.com
    - SMTP_PORT=587
    - SMTP_USER=xxxx@gmail.com
    - SMTP_PASS=xxxxxxxx
    - SMTP_STARTTLS=true
    - SMTP_TLS=false
    - SMTP_AUTHENTICATION=login
  volumes:
    - /home/vagrant/docker-gitlab/gitlab-data/gitlab:/home/git/data
redis:
  restart: always
  image: sameersbn/redis:latest
  volumes:
    - /home/vagrant/docker-gitlab/gitlab-data/redis:/var/lib/redis
```

---

### Controll Container

---

#### Run

```shell-session
$ sudo docker-compose up -d
$ sudo docker-compose ps
          Name                         Command              State                         Ports
----------------------------------------------------------------------------------------------------------------------
dockergitlab_gitlab_1       /sbin/entrypoint.sh app:start   Up      0.0.0.0:xxxx->22/tcp, 443/tcp, 0.0.0.0:xxxx->80/tcp
dockergitlab_postgresql_1   /sbin/entrypoint.sh             Up      5432/tcp
dockergitlab_redis_1        /sbin/entrypoint.sh             Up      6379/tcp
```

--

コンテナ起動後は、GitLabが起動しているかログを確認すると良いです。  
※例:8.2.0

```shell-session
$ sudo docker exec -it dockergitlab_gitlab_1 tail -n 20 /var/log/gitlab/gitlab/sidekiq.log
```

--

上記のdocker-compose.ymlで起動した場合は、volumesに記述してあるように、下記のディレクトリができているはずです。

 - docker-gitlab/gitlab-data/postgresql
 - docker-gitlab/gitlab-data/gitlab
 - docker-gitlab/gitlab-data/redis

---

#### Set Backup file

--

GitLabは標準機能として、バックアップファイルを作成することができます。  
そのバックアップファイルを起動時に作成されたgitlab-data/gitlab/backups/へ配置して下さい。

```shell-session
$ cp -a backup/xxxxxxxx_gitlab_backup.tar gitlab-data/gitlab/backups/
```

---

#### Restore

--

今回は元々使用していたGitLabサーバー（7.12.2）で作成したバックアップファイルをdockerで起動したGitLabサーバー（7.12.2）でリストアします。

```shell-session
$ sudo docker exec -it dockergitlab_gitlab_1 bash
root@4e2a404f9d38:/home/git/gitlab# /sbin/entrypoint.sh app:rake gitlab:backup:restore
root@4e2a404f9d38:/home/git/gitlab# exit
```

docker-compose.ymlで設定した。GITLAB_HOST:GITLAB_PORTへアクセスすれば、復元されていることの確認ができます。

---

#### Create Backup file

--

起動していたGitlabコンテナを停止し、バックアップファイルを作成します。

```shell-session
$ sudo docker stop dockergitlab_gitlab_1
$ sudo docker rm dockergitlab_gitlab_1
```

backupには次のようなシェルを作ってしまうと楽かもしれません。
以降はGITLAB_VERSIONを変更するのみで良いからです。

--

```shell-session:backup.sh
#!/bin/bash

GITLAB_VERSION="7.12.2"

docker run --name gitlab -it --rm \
  --link dockergitlab_redis_1:redisio \
  --link dockergitlab_postgresql_1:postgresql \
  -p xxxx:22 -p xxxx:80 \
  --env TZ=Asia/Tokyo \
  --env GITLAB_TIMEZONE=Tokyo \
  --env GITLAB_SECRETS_DB_KEY_BASE=xxxxxxxxx \
  --env GITLAB_HOST=xxx.xxx.xxx.xxx \
  --env GITLAB_PORT=xxxx \
  --env GITLAB_SSH_PORT=xxxx \
  sameersbn/gitlab:${GITLAB_VERSION} \
  app:rake gitlab:backup:create
```

---

#### Repeat Backup and Restore

--

docker-compose.ymlのバージョンを修正し、backup.shのバージョンも修正します。  
ここからは前述したことの繰り返しになります。  
7.12.2 => 7.14.3 => 8.1.4 => 8.2.0 => 8.3.0-1の順にバージョンを上げて下さい。

```shell-session
$ vim docker-compose.yml
$ sudo docker-compose up -d
```

--

後方互換性が保たれている場合は、GitLabコンテナを起動するだけで、リストアが可能です。  
必ず7.12.2 => 7.14.3 => 8.1.4 => 8.2.0 => 8.3.0-1の順を守って下さい。  
※GITLAB_HOST:GITLAB_PORTへアクセスし、動作を確認後、コンテナを停止しましょう。早過ぎると、データの移行が完全にできていない場合があります。

```shell-session
$ sudo docker stop dockergitlab_gitlab_1
$ sudo docker rm dockergitlab_gitlab_1
$ vim backup.sh
$ sudo sh backup.sh
```

---

#### Check Version of GitLab

--

ここまで終わったら、動作を確認してみましょう。  
GITLAB_HOST:GITLAB_PORTへアクセスし、バージョンを確認してみます。

![gitlab_version.png](https://qiita-image-store.s3.amazonaws.com/0/58725/b0772eaa-fc51-be92-ef41-097647355716.png)

---

### Conclusion

--

とても簡単にGitLabのバージョンを上げることができました。  
dockerだと、やり直しも簡単にできるので、とりあえず試してみる…という気持ちで触ってみると良いと思います。  
Let's play docker!!

---

## Thank you for your kind attention.
