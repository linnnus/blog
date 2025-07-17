# How to treat libgit2 blobs as file handles

I figured I'd document the solution to my hyper-specific problem
in case anyone in the future has the same issue.

So here's the setup:
I am using [libgit2][libgit] to operate on the contents of some files stored in a repository
and I would like to pass the contents of a blob (i.e. a piece of data in the Git store) to `foo`,
but libgit2 only lets me access the content of the blob through [`git_blob_rawcontent`][git_blob_rawcontent]
which returns a `char *`
and `foo` only operates on `FILE *`s.

The POSIX standard comes to the rescue!
It defines the special function [`fmemopen`][fmemopen] which allows one to construct a file handle from a piece of memory.
Here's an example from the docs:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char buffer[] = "foobar";

int main (void)
{
    int ch;
    FILE *stream;

    stream = fmemopen(buffer, strlen (buffer), "r");
    if (stream == NULL) {
        perror("failed to fmemopen buffer");
        exit(EXIT_FAILURE);
    }

    while ((ch = fgetc(stream)) != EOF) {
        printf("Got %c\n", ch);
    }

    fclose(stream);
    return EXIT_SUCCESS;
}
```

It produces the following output.

```
Got f
Got o
Got o
Got b
Got a
Got r
```

Just what I was looking for!
With this I can wrap the result of `git_blob_rawcontent` in a `FILE *` and pass it to `foo`.

```c
#include <git2.h>
#include <stdio.h>
git_blob *blob = /* ... */;
FILE *fp = fmemopen(git_blob_rawcontent(blob), git_blob_rawsize(blob), "rb");
foo(fp);
```

Hopefully this is the solution to your hyper-specific problem as well :^)

[libgit]: https://libgit2.org
[git_blob_rawcontent]: https://libgit2.org/libgit2/#v0.28.3/group/blob/git_blob_rawcontent
[fmemopen]: https://pubs.opengroup.org/onlinepubs/9699919799/functions/fmemopen.html
