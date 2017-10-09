//
//  ApplicativeError.swift
//  CategoryCore
//
//  Created by Tomás Ruiz López on 29/9/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public protocol ApplicativeError : Applicative {
    associatedtype E
    
    func raiseError<A>(_ e : E) -> HK<F, A>
    func handleErrorWith<A>(_ fa : HK<F, A>, _ f : (E) -> HK<F, A>) -> HK<F, A>
}

public extension ApplicativeError {
    public func handleError<A>(_ fa : HK<F, A>, _ f : (E) -> A) -> HK<F, A> {
        return handleErrorWith(fa, { a in pure(f(a)) })
    }
    
    public func attempt<A>(_ fa : HK<F, A>) -> HK<F, Either<E, A>> {
        return handleErrorWith(map(fa, Either<E, A>.right), { e in pure(Either<E, A>.left(e)) })
    }
    
    public func catchError<A>(_ f : () throws -> A, recover : (Error) -> E) -> HK<F, A> {
        do {
            return pure(try f())
        } catch {
            return raiseError(recover(error))
        }
    }
}
