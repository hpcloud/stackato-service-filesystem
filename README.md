# filesystem service

This repository contains the code for the Stackato filesystem service. This service provides exposes a 'filesystem' provider using plain directories and Unix users/permissions as access control, as well as sshfs for remote access to the service (the private key, username, and host making up the credentials).

Once a user provisions a filesystem service, it will automatically be mounted in to app containers at /app/fs/servicename, providing a directory which will be shared among all deployed instances of the app (e.g. if one instance creates /app/fs/servicename/abc, that file will be available to all instances of the app, at the same path).

This can be used for asset storage, caching, and many other situations requiring persistent data storage to be available.
