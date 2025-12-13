## Code Block Test

This @include directive outside code block should work:
@include ./real-include.md

But this one inside a code block should NOT be processed:

```markdown
@include ./should-not-include.md
```

End of file.
