# 環境構築

Mac上にipython-notebook, vagrant VM を立てて、そのVMにプロビジョニングすることを考える。  
プロビジョニングする内容はansibleであれば、特に指定はない（apacheなどが簡単で良いかと）


## ipython-notebook の設定

このマシン(MacOS X)には既にipython-notebookが入っていたため、それをupgradeする。

```Bash
$ sudo pip install --upgrade ipython==2.4.1
$ sudo pip install requests paramiko ansible
$ sudo pip install pylint
$ sudo pip install pyyaml
```

```Bash
$ sh run/ipython-start.sh
$ sh run/ipython-stop.sh
```

起動すると、下記リンクで確認できる。  
[http://localhost:8080](http://localhost:8080)


## Vagrant VM の設定

VMの起動

```
$ cd vagrantfile/ubuntu1404/
$ vagrant up
```


## SSH の設定
ホストOSからゲストOSへAnsibleのコマンドが実行できるようSSHの設定

```
$ vi ~/.ssh/config

# 以下を追記する([PATH]は環境に合わせて)
Host 192.168.33.*
  IdentityFile [PATH]/vagrantfile/ubuntu1404/.vagrant/machines/default/virtualbox/private_key
  User vagrant
  StrictHostKeyChecking no
```

