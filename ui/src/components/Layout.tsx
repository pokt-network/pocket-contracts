// layout with children

export const Layout = ({ children }: React.PropsWithChildren) => (
    <div className="flex flex-col h-screen items-center bg-app">{children}</div>
)