/// Headless platforms (`flutter test`) have no tabs.
Stream<void> platformPageVisibleAgain() => const Stream.empty();
