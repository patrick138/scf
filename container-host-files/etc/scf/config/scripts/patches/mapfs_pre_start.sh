#! /usr/bin/env bash

set -e

PATCH_DIR=/var/vcap/jobs-src/mapfs/templates
SENTINEL="${PATCH_DIR}/${0##*/}.sentinel"

if [ -f "${SENTINEL}" ]; then
  exit 0
fi

patch -d "$PATCH_DIR" --force -p0 <<'PATCH'
--- install.erb
+++ install.erb
@@ -4,22 +4,28 @@ set -e -x
 
 echo "Installing fuse"
 
-codename=$(lsb_release -c | awk '{print $2}')
-if [ "$codename" == "trusty" ]; then
-  (
-  flock -x 200
-  dpkg  --force-confdef -i /var/vcap/packages/mapfs-fuse/fuse_2.9.2-4ubuntu4.14.04.1_amd64.deb
-  ) 200>/var/vcap/data/dpkg.lock
-elif [ "$codename" == "xenial" ]; then
-  (
-  flock -x 200
-  dpkg  --force-confdef -i /var/vcap/packages/mapfs-fuse/fuse_2.9.4-1ubuntu3.1_amd64.deb
-  ) 200>/var/vcap/data/dpkg.lock
+if test -f /usr/bin/lsb_release
+then
+    codename=$(lsb_release -c | awk '{print $2}')
+    if [ "$codename" == "trusty" ]; then
+	(
+	    flock -x 200
+	    dpkg  --force-confdef -i /var/vcap/packages/mapfs-fuse/fuse_2.9.2-4ubuntu4.14.04.1_amd64.deb
+	) 200>/var/vcap/data/dpkg.lock
+    elif [ "$codename" == "xenial" ]; then
+	(
+	    flock -x 200
+	    dpkg  --force-confdef -i /var/vcap/packages/mapfs-fuse/fuse_2.9.4-1ubuntu3.1_amd64.deb
+	) 200>/var/vcap/data/dpkg.lock
+    fi
+else
+    # opensuse, sle stemcells do not have lsb_release installed
+    zypper --non-interactive --quiet install fuse
 fi
 
-modprobe fuse
+modprobe fuse || ( echo 'Kernel module "fuse" required, missing. Please update your platform.' && false )
 groupadd fuse || true
-adduser vcap fuse
+useradd fuse -g vcap
 chown root:fuse /dev/fuse
 cat << EOF > /etc/fuse.conf
 user_allow_other
PATCH

touch "${SENTINEL}"

exit 0
