extension __Slab where S: ~Copyable {

    public enum Error: Swift.Error, Sendable, Equatable {

        case full

        case vacant

        case occupied
    }
}
