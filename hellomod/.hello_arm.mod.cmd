savedcmd_/build/workspace/code/hellomod/hello_arm.mod := printf '%s\n'   hello_arm.o | awk '!x[$$0]++ { print("/build/workspace/code/hellomod/"$$0) }' > /build/workspace/code/hellomod/hello_arm.mod
