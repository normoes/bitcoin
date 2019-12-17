## Supported tags and respective `Dockerfile` links
* `latest` ([Dockerfile](https://github.com/XMRto/bitcoin/blob/master/Dockerfile))

---

For running `bitcoind` or `bitcoin-cli` in a docker container.

In order to switch from user and password based authentication (using `-rpcuser` and `-rpcpassword`) to `-rpcauth` it is worth mentioning, that the docker image needs to be configured in a certain way (using environment variables):
* `-rpcuser` and `-rpcpassword`:
  - `RPC_USER` **and** `RPC_PASSWORD` are expected.
* `-rpcauth`:
  - `RPC_AUTH` is expected, `RPC_USER` and `RPC_PASSWORD` must not be set.
  - Create a value for `-rpcauth` (`RPC_AUTH`):
      + Run the script `rpcauth.py` to create credentials.
      + The script can be found in the official bitcoin github repository:
      ```
          share/rpcauth/rpcauth.py
          # Also have a look at the README file
          share/rpcauth/README.md
      ```
      + The result will be a string in the following format:
        - `<username>:<token>`
        - This is what `RPC_AUTH` is to be configured with.
      + Additionally you will a `<password>` which is to be used to configure the clients connecting to the bitcoind RPC.

