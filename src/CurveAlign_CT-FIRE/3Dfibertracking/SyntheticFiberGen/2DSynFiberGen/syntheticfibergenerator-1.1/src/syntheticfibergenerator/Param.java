/*
 * Written for the Laboratory for Optical and Computational Instrumentation, UW-Madison
 *
 * Author: Matthew Dutson
 * Email: dutson@wisc.edu, mattdutson@icloud.com
 * GitHub: https://github.com/uw-loci/syntheticfibergenerator
 *
 * Copyright (c) 2019, Board of Regents of the University of Wisconsin-Madison
 */

package syntheticfibergenerator;


/**
 * A wrapper around a parameter which defines the behavior for parsing from a string and verifying that the value is in
 * the correct range.
 * <p>
 * TODO: Flatten value field on serialization
 *
 * @param <T> The value's type
 */
class Param<T extends Comparable<T>> {

    /**
     * Interface for a parsing functor.
     *
     * @param <U> The type returned by the call to parse()
     */
    interface Parser<U> {

        /**
         * @param string The string to parse
         * @return An object of type {@code U} which was parsed from the input
         * @throws IllegalArgumentException If a value of type {@code U} can't be parsed from the input string
         */
        U parse(String string) throws IllegalArgumentException;
    }

    /**
     * Interface for a value verification functor.
     *
     * @param <U> The type being verified; must be comparable
     */
    interface Verifier<U extends Comparable<U>> {

        /**
         * @param value The value to verify
         * @param bound An bound for the value (see static methods in {@code Params} for examples
         * @throws IllegalArgumentException If the value is outside the allowed range
         */
        void verify(U value, U bound) throws IllegalArgumentException;
    }


    // Value of the parameter
    private T value;

    // A short (1-3 word) name for the parameter
    private transient String name;

    // A longer string giving details about the parameter's usage and units
    private transient String hint;


    /**
     * @return A reference to the value
     */
    T value() {
        return value;
    }

    /**
     * @return An empty string if {@code value} is null, {@code value.toString()} otherwise
     */
    String string() {
        return value == null ? "" : value.toString();
    }

    /**
     * Sets the name string.
     *
     * @param name The name to assign
     */
    void setName(String name) {
        this.name = name;
    }

    /**
     * @return An empty string if {@code name} is null, {@code name} otherwise
     */
    String name() {
        return name == null ? "" : name;
    }

    /**
     * Sets the hint string.
     *
     * @param hint The hint to assign
     */
    void setHint(String hint) {
        this.hint = hint;
    }

    /**
     * @return An empty string if {@code hint} is null, {@code hint} otherwise
     */
    String hint() {
        return hint == null ? "" : hint;
    }

    /**
     * Attempts to parse a value of type {@code T} from a string.
     *
     * @param string The string to parse
     * @param parser An instance of {@code Parser<T>} which defines the parsing behavior
     * @throws IllegalArgumentException If the string contains only whitespace or the parse fails
     */
    void parse(String string, Parser<T> parser) throws IllegalArgumentException {
        if (string.replaceAll("\\s+", "").isEmpty()) {
            throw new IllegalArgumentException("Value of \"" + name() + "\" must be non-empty");
        }
        try {
            value = parser.parse(string);
        } catch (Exception e) {
            throw new IllegalArgumentException("Unable to parse value \"" + string + "\" for parameter \"" + name() + '\"');
        }
    }

    /**
     * Verifies that the value of this parameter is in the correct range.
     *
     * @param bound    The bound against which this parameter's value is checked by a call to {@code
     *                 verifier.verify(value, bound)}
     * @param verifier An instance of {@code Verifier<T>} which throws an exception if the value is out of range
     * @throws IllegalArgumentException If {@code verifier.verify(value, bound)} fails (throws an exception)
     */
    void verify(T bound, Verifier<T> verifier) throws IllegalArgumentException {
        try {
            verifier.verify(value, bound);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Value of \"" + name() + "\" " + e.getMessage() + " " + bound);
        }
    }

    /**
     * Used as a {@code Verifier} to check that the value is less than the bound.
     *
     * @param value The value to check
     * @param max   The bound; in this case the non-inclusive maximum
     * @param <U>   The type of {@code value} and {@code max}
     */
    static <U extends Comparable<U>> void less(U value, U max) {
        if (value.compareTo(max) >= 0) {
            throw new IllegalArgumentException("must be less than");
        }
    }

    /**
     * Used as a {@code Verifier} to check that the value is greater than than the bound.
     *
     * @param value The value to check
     * @param min   The bound; in this case the non-inclusive minimum
     * @param <U>   The type of {@code value} and {@code max}
     */
    static <U extends Comparable<U>> void greater(U value, U min) {
        if (value.compareTo(min) <= 0) {
            throw new IllegalArgumentException("must be greater than");
        }
    }

    /**
     * Used as a {@code Verifier} to check that the value is less than or equal to the bound.
     *
     * @param value The value to check
     * @param max   The bound; in this case the inclusive maximum
     * @param <U>   The type of {@code value} and {@code max}
     */
    static <U extends Comparable<U>> void lessEq(U value, U max) {
        if (value.compareTo(max) > 0) {
            throw new IllegalArgumentException("must be less than or equal to");
        }
    }

    /**
     * Used as a {@code Verifier} to check that the value is greater than or equal to than the bound.
     *
     * @param value The value to check
     * @param min   The bound; in this case the inclusive minimum
     * @param <U>   The type of {@code value} and {@code max}
     */
    static <U extends Comparable<U>> void greaterEq(U value, U min) {
        if (value.compareTo(min) < 0) {
            throw new IllegalArgumentException("must be greater than or equal to");
        }
    }
}


/**
 * An extension of {@code Param<T>} with a boolean flag indicating whether the user has decided to enable the
 * functionality associated with this parameter.
 *
 * @param <T> The value's type
 */
class Optional<T extends Comparable<T>> extends Param<T> {

    // The flag indicating whether this parameter will be used
    boolean use;


    /**
     * If {@code use} is false nothing occurs. Otherwise {@code Param.parse(string, parser)} is called.
     *
     * @param string The string to parse
     * @param parser An instance of {@code Parser<T>} which defines the parsing behavior
     * @throws IllegalArgumentException If {@code use == true} and the string contains only whitespace or the parse
     *                                  fails
     */
    @Override
    void parse(String string, Parser<T> parser) throws IllegalArgumentException {
        if (use) {
            super.parse(string, parser);
        }
    }

    /**
     * Assigns the value of {@code use} and then calls {@code parse(string, parser)}.
     *
     * @param use    Whether this parameter will be used
     * @param string The string to parse
     * @param parser An instance of {@code Parser<T>} which defines the parsing behavior
     * @throws IllegalArgumentException If {@code use == true} and the string contains only whitespace or the parse
     *                                  fails
     */
    void parse(boolean use, String string, Parser<T> parser) throws IllegalArgumentException {
        this.use = use;
        parse(string, parser);
    }

    /**
     * If {@code use} is false nothing occurs. Otherwise {@code Param.verify(bound, verifier)} is called.
     *
     * @param bound    The bound against which this parameter's value is checked by a call to {@code
     *                 verifier.verify(value, bound)}
     * @param verifier An instance of {@code Verifier<T>} which throws an exception if the value is out of range
     * @throws IllegalArgumentException If {@code use == true} and {@code verifier.verify(value, bound)} fails (throws
     *                                  an exception)
     */
    @Override
    void verify(T bound, Verifier<T> verifier) throws IllegalArgumentException {
        if (use) {
            super.verify(bound, verifier);
        }
    }
}