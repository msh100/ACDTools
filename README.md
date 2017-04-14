# ACDTools

ACDTools is a script made to assist with the management of an Amazon Drive mount by simplifying mounting and making changes to encrypted datasets on Amazon Drive.

When you mount with ACDTools, 4 different mountpoints will be created however you should only be reading from and writing to one of them (UnionFS, as visualised below). 
The others exist to achieve the setup we have had the best performance and reliability from.

We mount UnionFS on top of your local storage, and then your decrypted Amazon Drive files.

```
             -- Local Files
UnionFS -- [
             -- (RO) Amazon Files -- Encrypted Amazon Files
```

When you intend to *write* data to your mount, it will be written to your local content. 
When you intent to *read* data from your mount, it will first check for the existence of data on your local storage and then on the decrypted Amazon Drive mount.
This mean that if a file exists locally it can be read without contacting Amazon and decrypting data.

Once you run `acdtools upload`, changes to local files will be reflected on Amazon Drive (they will be read from the encrypted representation of your local files). 
It is therefore recommended to run this every night via crontab. 
After a successful upload is complete, ACDTools will delete files older than a configureable amount of days from your local storage.


## Installation

ACDTools depends on:

 * bash
 * FUSE (as this is a kernel module, OpenVZ containers may experience issues)
 * [`acd_cli`](https://github.com/yadayada/acd_cli)
 * [encfs](https://github.com/vgough/encfs)
 * [UnionFS-FUSE](https://github.com/rpodgorny/unionfs-fuse)
 * [sqlite3](https://www.sqlite.org/)
 * [git](https://git-scm.com/) (*used because a fork of `acd_cli` is pulled*)

```
git clone https://github.com/msh100/ACDTools.git
```

Once cloned, copy the `vars.template` file to `vars` and edit the variables. If you are not using an HTTP(S) proxy, you can remove those lines entirely.


### Configuration Options

 Variable       | Description
----------------|-----------------------
`MOUNTBASE`     | The local path where all the required mointpoints will be placed. It is recommended that this is a hidden directory (directory with leading dot) as you should not be reading or writing here manually.
`DATADIR`       | The local path where you want to be able to read and write your data (The UnionFS mountpoint).
`ENCFSPASS`     | Password associated with your ENCFS configuration.
`ACDSUBDIR`     | The directory on Amazon Drive you wish to mount.
`ACDCLI`        | Your path to `acd_cli`. This can usually be determined by running `which acd_cli`.
`LOCALDAYS`     | The number of days you wish to preserve your files locally.
`ENCFS6_CONFIG` | The local path to your ENCFS configuration XML file.
`HTTP_PROXY`*   | HTTP proxy endpoint.
`HTTPS_PROXY`*  | HTTPS proxy endpoint.

> \* Optional. It's also unknown if HTTP is ever used instead of HTTPS however is unlikely.


## Usage

By default, ACDTools will use first use a configuration file called `vars` in the same directory as the script. Next it will try in your working directory. However if `-c` is defined, it will always use the configuration file passed at run time (providing it exists).

Example:

```
./acdtools -c /path/to/my/config mount
```


### Mount the Entire Setup

Running `mount` will mount all the required FUSE filesystems and unmount any which are currently mounted. 
It is recommended you call this at boot.

```
./acdtools mount
```


### Unmount

Running `unmount` will unmount all FUSE filesystems used by ACDTools.

```
./acdtools unmount
```


### Upload Files

This will upload all your local files (encrypted) which do not match that already existing on Amazon Drive. 
It is recommended you call this nightly.

`upload` will also delete local files older than `LOCALDAYS` defined in your configuration file.

```
./acdtools upload
```


### Sync

As `acd_cli` keeps a local database of your files which are stores on Amazon Drive, it does not know if you upload files remotely. To update the node cache database you can use `sync`.

```
./acdtools sync
```


### Reflect Locally Deleted Files on Amazon

As Amazon Drive is mounted as read-only, it is not possible to delete files. UnionFS handles this by creating an object on the local layer of the UnionFS mount which hides the file from view once it is deleted.

This means that the file will still persist on Amazon until you run a `syncdeletes`.

`syncdeletes` is automatically run on an `upload`.

```
./acdtools syncdeletes
```


# Tests

TODO.
