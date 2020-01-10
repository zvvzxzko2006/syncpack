# syncpack utilities #
one-key construct development work space.

## Quick Start ##
1. clone or download zip and decompress to your disk.

    $ cd /home/user/syncpack
    $ unzip -x syncpack.zip

2. create a symble link in your system PATH environment

    # cd /usr/bin
    # ln -s /home/user/syncpack/syncpack.sh syncpack

3. create your empty workspace

    $ mkdir /home/user/workspace

4. initialize you workspace as cyber

    $ syncpack init git@github:example/workspace master syncscript.bash

5. synchronize workspace dependency

    $syncpack sync

## Example ##
construct cyber-talkers development workspace

    ~/workspace/test$ mkdir cyber-ws
    ~/workspace/test$ cd cyber-ws
    ~/workspace/test/cyber-ws$ syncpack init https://10.8.202.203/syncpack-workspaces/cyber-talker-ws.git master aarch64-ubuntu1604.sh
    ~/workspace/test/cyber-ws$ syncpack sync
    ~/workspace/test/cyber-ws$ cd cyber-talkers
    ~/workspace/test/cyber-ws/cyber-talkers$ mkdir build
    ~/workspace/test/cyber-ws/cyber-talkers$ cd build
    ~/workspace/test/cyber-ws/cyber-talkers/build$ cmake ..
    ~/workspace/test/cyber-ws/cyber-talkers/build$ make -j11

