public enum SelectionFocusResolver {
    public static func resolve<Element>(
        frontmostApplication: () -> Element?,
        systemWide: () -> Element?
    ) -> Element? {
        frontmostApplication() ?? systemWide()
    }
}
