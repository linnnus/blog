# How to give Simple Voice Chat microphone permissions on MacOS

<details>

<summary>tl;dr: Click here to view a step-by-step guide</summary>

If you voice that doesn't work
and you're getting an error complaining about MacOS permissions,
you can execute the following code in Terminal.app
to give the Minecraft launcher the correct permissions.
After executing the code, restart the your computer.

```sh
sqlite3 "/Users/$USER/Library/Application Support/com.apple.TCC/TCC.db" <<EOF
INSERT INTO access VALUES(
	'kTCCServiceMicrophone',        -- service
	'com.mojang.minecraftlauncher', -- client
	0, -- client_type (0 = bundle id)
	2, -- auth_value (2 = allowed)
	3, -- auth_reason (3 = user set)
	1, -- auth_version (always 1)
	-- csreq:
	X'fade0c00000000a80000000100000006000000060000000600000006000000020000001c636f6d2e6d6f6a616e672e6d696e6563726166746c61756e636865720000000f0000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a48523939325a454145360000',
	NULL,       -- policy_id
	NULL,       -- indirect_object_identifier_type
	'UNUSED',   -- indirect_object_identifier
	NULL,       -- indirect_object_code_identity
	0,          -- flags
	1612407199, -- last_updated
	NULL,     -- pid (no idea what this does)
	NULL,     -- pid_version (no idea what this does)
	'UNUSED', -- boot_uuid (no idea what this does)
	0         -- last_reminded
);
EOF
```

This is confirmed to be working on the following software versions.

* MacOS 14.5 (23F79)
* Minecraft 1.21.1
* Fabric 0.16.4
* Simple Voice Chat 2.5.21

It is probably going to break slightly in future updates to MacOS.
In that case see the rest of this post.

</details>

Yesterday I wanted to play Minecraft on a server
that was using the [Simple Voice Chat plugin][svc].
However, when I joined the server,
I got a warning message about
the Minecraft launcher not having microphone permissions.
This makes sense:
MacOS applications have to explicitly request permissionto do stuff like listening to the microphone
and the Minecraft launcher doesn't have any reason to request that permission
so it doesn't get it!

The recommended solution on [Simple Voice Chat's wiki][svc-wiki] is to use a [Prism], a custom launcher.
I didn't quite feel like installing and learning some random launcher just to fix this one issue
so I started looking around for other solutions.
MacOS has to be storing the permissions *somewhere*
and if I could just manually enter Minecraft into there,
I wouldn't have to go through Prism.

After a bit of searching
I found [this article][tcc-deepdive]
which explains that <abbr title="Transparency, Consent, and Control">TCC</abbr> is the mechanism by which MacOS manages permissions
and it stores all its per-user data in a file located[^shvar] at
`/Users/$USER/Library/Application Support/com.apple.TCC/TCC.db`.
This file is actually just an SQLite database
which we can modify using a generic SQLite tool like `sqlite3`.

; Don't put this footnote right after the path, as readers might accidentally include it when copying the path
[^shvar]: Here I'm using `$USER` as a place-holder for the current user's username.
It should just be expanded when using it in Terminal.
When doing so, be careful about the space in the path!

```sh
$ sqlite3 "/Users/$USER/Library/Application Support/com.apple.TCC/TCC.db"
```

Executing the above will open an interactive SQL REPL.
We can see all the tables contained in the database with [a special command][dot-command].

```
sqlite> .table
access            active_policy     expired
access_overrides  admin             policies
```

The article also explained that the table we're mainly interested in is called `access`.
We can see its schema using the `.schema` command.
Of note are the fields `service` and `client` which specify the permission and application respectively.
See [the article][tcc-deepdive] for the meaning of the rest of the columns.

```sql
sqlite> .schema access
CREATE TABLE access (
	service        TEXT        NOT NULL,
	client         TEXT        NOT NULL,
	client_type    INTEGER     NOT NULL,
	auth_value     INTEGER     NOT NULL,
	auth_reason    INTEGER     NOT NULL,
	auth_version   INTEGER     NOT NULL,
	csreq          BLOB,
	policy_id      INTEGER,
	indirect_object_identifier_type    INTEGER,
	indirect_object_identifier         TEXT NOT NULL DEFAULT 'UNUSED',
	indirect_object_code_identity      BLOB,
	flags          INTEGER,
	last_modified  INTEGER     NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
	pid INTEGER,
	pid_version INTEGER,
	boot_uuid TEXT NOT NULL DEFAULT 'UNUSED',
	last_reminded INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (service, client, client_type, indirect_object_identifier),
	FOREIGN KEY (policy_id) REFERENCES policies(id) ON DELETE CASCADE ON UPDATE CASCADE
);
```

Now all we have to do is give `kTCCServiceMicrophone` permissions to `com.mojang.minecraftlauncher`
by inserting it in the `access` table
as if the permission had been requested and granted by the user.
We can do that with the following query:

```sql
INSERT INTO access VALUES(
	'kTCCServiceMicrophone',        -- service
	'com.mojang.minecraftlauncher', -- client
	0, -- client_type (0 = bundle id)
	2, -- auth_value (2 = allowed)
	3, -- auth_reason (3 = user set)
	1, -- auth_version (always 1)
	-- csreq:
	X'fade0c00000000a80000000100000006000000060000000600000006000000020000001c636f6d2e6d6f6a616e672e6d696e6563726166746c61756e636865720000000f0000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a48523939325a454145360000',
	NULL,       -- policy_id
	NULL,       -- indirect_object_identifier_type
	'UNUSED',   -- indirect_object_identifier
	NULL,       -- indirect_object_code_identity
	0,          -- flags
	1612407199, -- last_updated
	NULL,     -- pid (no idea what this does)
	NULL,     -- pid_version (no idea what this does)
	'UNUSED', -- boot_uuid (no idea what this does)
	0         -- last_reminded
);
```

Generating a value for the `csreq` column was a little tricky.
Luckily, [this Stackoverflow post][csreq-gen] has the answer.
It basically boils down to this[^csreq-explain]:

```sh
REQ_STR=$(codesign -d -r- /Applications/Minecraft.app/ 2>&1 | awk -F ' => ' '/designated/{print $2}')
echo "$REQ_STR" | csreq -r- -b /tmp/csreq.bin
REQ_HEX=$(xxd -p /tmp/csreq.bin  | tr -d '\n')
echo "X'$REQ_HEX'"
```

[^csreq-explain]: Look at [the Stackoverflow answer][csreq-explain] for an explanation of
how the commands work.

If you looked closely,
you have probably also noticed
that the schema I found has a few more columns than the one in the article.
I assume these have been added in later MacOS updates.
When constructing my `INSERT` query, I just left the values as `NULL` and `'UNUSED'`
because that's what similar rows in the table seemed to be doing.

Now I just needed to make the changes to the database take effect.
I didn't know if/how I needed to restart TCC,
so I just rebooted my computer.

Afterwards I confirmed
that Minecraft was now showing up under the microphone permission in settings.
Yay, we did it!

[svc]: https://modrinth.com/plugin/simple-voice-chat
[svc-wiki]: https://modrepo.de/minecraft/voicechat/wiki/macos
[tcc-deepdive]: https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive
[Prism]: https://prismlauncher.org/
[dot-command]: https://www.sqlite.org/cli.html#special_commands_to_sqlite3_dot_commands_
[csreq-gen]: https://stackoverflow.com/a/57259004
