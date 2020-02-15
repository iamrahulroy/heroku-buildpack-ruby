## Check for .bundle/config before running bundle

If there are any user set bundle environment variables (like gem credentials), these will be persisted in .bundle/config automatically, so we now check for .bundle/config before any bundle commands have been to avoid reporting a false positive.
