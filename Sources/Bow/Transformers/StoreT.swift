/// Witness for the `StoreT<S, W, A>` data type. To be used in simulated Higher Kinded Types.
public final class ForStoreT {}

/// Partial application of the `StoreT` type constructor, omitting the last parameter.
public final class StoreTPartial<S, W>: Kind2<ForStoreT, S, W> {}

/// Higher Kinded Type alias to improve readability of `Kind<StoreTPartial<S, W>, A>`.
public typealias StoreTOf<S, W, A> = Kind<StoreTPartial<S, W>, A>

/// Witness for the `Store<S, A>` data type. To be used in simulated Higher Kinded Types.
public typealias ForStore = ForStoreT

/// Partial application of the `Store` type constructor, omitting the last parameter.
public typealias StorePartial<S> = StoreTPartial<S, ForId>

/// Higher Kinded Type alias to improve readability of `Kind<StorePartial<S>, A>`.
public typealias StoreOf<S, A> = StoreTOf<S, ForId, A>

/// The Store type is equivalent to the StoreT type, with the base Comonad being Id.
public typealias Store<S, A> = StoreT<S, ForId, A>

/// The Store Comonad Transformer. This Comonad Transformer extends the context of a value in the base Comonad so that it depends on a position of the type of the state.
public final class StoreT<S, W, A>: StoreTOf<S, W, A> {
    /// Rendering function in the context of the base Comonad.
    public let render: Kind<W, (S) -> A>
    
    /// Current focus of this Store.
    public let state: S
    
    /// Safe downcast.
    ///
    /// - Parameter value: Value in the higher-kind form.
    /// - Returns: Value cast to StoreT.
    public static func fix(_ value: StoreTOf<S, W, A>) -> StoreT<S, W, A> {
        value as! StoreT<S, W, A>
    }
    
    /// Initializes a StoreT.
    ///
    /// - Parameters:
    ///   - state: Current focus of the Store.
    ///   - render: Rendering function of the Store.
    public init(_ state: S, _ render: Kind<W, (S) -> A>) {
        self.state = state
        self.render = render
    }
}

public extension StoreT where W: Comonad {
    /// Moves the store into a new state.
    ///
    /// - Parameter newState: New state for the store.
    /// - Returns: A new store focused on the provided state.
    func move(_ newState: S) -> StoreT<S, W, A> {
        self.duplicate()^.peek(newState)^
    }
}

/// Safe downcast.
///
/// - Parameter value: Value in the higher-kind form.
/// - Returns: Value cast to StoreT.
public postfix func ^<S, W, A>(_ value: StoreTOf<S, W, A>) -> StoreT<S, W, A> {
    StoreT.fix(value)
}

// MARK: Syntax for Store

extension StoreT where W == ForId {
    /// Initializes a Store.
    ///
    /// - Parameters:
    ///   - state: Current focus of the store.
    ///   - render: Rendering function.
    public convenience init(_ state: S, _ render: @escaping (S) -> A) {
        self.init(state, Id(render))
    }
}

// MARK: Instance of `Invariant` for `StoreT`

extension StoreTPartial: Invariant where W: Functor {}

// MARK: Instance of `Functor` for `StoreT`

extension StoreTPartial: Functor where W: Functor {
    public static func map<A, B>(_ fa: StoreTOf<S, W, A>, _ f: @escaping (A) -> B) -> StoreTOf<S, W, B> {
        StoreT(fa^.state, fa^.render.map { ff in ff >>> f })
    }
}

// MARK: Instance of `Applicative` for `StoreT`

extension StoreTPartial: Applicative where W: Applicative, S: Monoid {
    public static func pure<A>(_ a: A) -> StoreTOf<S, W, A> {
        StoreT(S.empty(), W.pure(constant(a)))
    }
    
    public static func ap<A, B>(_ ff: StoreTOf<S, W, (A) -> B>, _ fa: StoreTOf<S, W, A>) -> StoreTOf<S, W, B> {
        StoreT(ff^.state.combine(fa^.state),
               W.map(ff^.render, fa^.render) { rf, ra in { s in rf(s)(ra(s)) } })
    }
}

// MARK: Instance of `Comonad` for `StoreT`

extension StoreTPartial: Comonad where W: Comonad {
    public static func coflatMap<A, B>(_ fa: StoreTOf<S, W, A>, _ f: @escaping (StoreTOf<S, W, A>) -> B) -> StoreTOf<S, W, B> {
        StoreT(fa^.state,
               fa^.render.coflatMap { wa in { s in f(StoreT(s, wa)) } })
    }
    
    public static func extract<A>(_ fa: StoreTOf<S, W, A>) -> A {
        fa^.render.extract()(fa^.state)
    }
}

// MARK: Instance of `ComonadStore` for `StoreT`

extension StoreTPartial: ComonadStore where W: Comonad {
    public static func position<A>(_ wa: StoreTOf<S, W, A>) -> S {
        wa^.state
    }
    
    public static func peek<A>(_ wa: StoreTOf<S, W, A>, _ s: S) -> A {
        wa^.render.extract()(s)
    }
}