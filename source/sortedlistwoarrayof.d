module sortedlistwoarrayof;
import std.functional : binaryFun;
import collections.commons;

/**
 * Implements a sorted list of type T.
 * The container ensures that all of it's elements are ordered after any insertion.
 * Has some optimization to stop searching after a given value has passed.
 * `cmp` can set both the direction of the array, and what parameters should be tested.
 * If `allowDuplicates` set false, the collection will act like a sorted set over an array, and won't allow any insertion of preexisting values.
 */
public struct SortedList(E, alias cmp = "a < b", bool allowDuplicates = true, alias equal = "a == b") {
	private E[]			_array;		///The array where the elements are stored.
	private size_t		begin;		///The position of the current front iteration.
	private size_t		end;		///The position of the current back iteration.
	/**
	 * Constructs a sorted list out from an array.
	 */
	public this(E[] _array) @safe nothrow pure {
		this._array.reserve = _array.length;
        foreach (E key; _array) {
            put(key);
        }
        
        assert(this._array.length == end);
	}
	/**
	 * Constructs a sorted list out from a range.
	 */
	public this(Range)(Range src) {
		foreach (E key; src) {
            put(key);
        }
        //assert(this._array.length == _array.length);
        assert(this._array.length == end);
	}
    /**
	 * Adds a new element while keeping the order intact.
	 *
	 * TO DO: Maybe even more optimizations? Maybe look where the element would fit, then shift that position?
	 */
	E put(E a) @safe nothrow pure {
		static if(!allowDuplicates){
			if(has(a)) return E.init;
		}
		_array.length = _array.length + 1;
		for(sizediff_t i = _array.length - 2 ; i >= 0 ; i--) {
			E b = _array[i];
			if(binaryFun!cmp(a, b)) { //first position found
				_array[i + 1] = a;
				end++;
				return a;
			} else {
				_array[i + 1] = b;
			}
		}
		_array[0] = a;
        end++;
		return a;
	}
	/**
	 * Removes the n-th element while keeping the order intact.
	 * Returns the removed element.
	 */
	E remove(size_t n) @safe nothrow pure {
		E result = _array[n];
		if(n != _array.length) {
			for ( ; n < _array.length - 1 ; n++) {
				_array[n] = _array[n + 1];
			}
		}
		_array.length = _array.length - 1;
		end--;
		return result;
    }
	static if(!allowDuplicates) {
		/**
		 * Removes the element which is equal with the given one if the template is set to not allow duplicates.
		 * Returns the removed element, or E.init if not found.
		 */
		E removeByElem(E a) @safe nothrow pure {
			foreach_reverse(i, b; _array) {
				if(binaryFun!equal(a, b)) return this.remove(i);
				else if(binaryFun!cmp(a, b)) break;
			}
			return E.init;
		}
		/**
		 * Returns whether the set has the given element.
		 */
		bool has(E a) @nogc @safe nothrow pure {
			foreach_reverse(i, b; _array) {
				if(binaryFun!equal(a,b)) return true;
				else if(binaryFun!cmp(a,b)) break;
			}
			return false;
		}
		auto opBinaryRight(string op)(const E key) @safe pure nothrow {
			static if (op == "in") {
				return has(key);
			} else static assert(0, "Operator not supported!");
		}
		/**
		 * Returns the amount of elements found in the set.
		 */
		size_t hasRange(R)(R range) @nogc @safe pure nothrow {
			size_t result;
			foreach (key; range) {
				if(has(key)) result++;
			}
			return result;
		}
		/**
		 * Returns the index of the given element, or throws an ElementNotFoundException if not found.
		 */
		size_t which(E a) @safe pure {
			foreach_reverse(i, b; _array) {
				if(binaryFun!equal(a,b)) return i;
				else if(binaryFun!cmp(a,b)) break;
			}
			throw new ElementNotFoundException("Element not found!");
		}
		/**
	 	 * Returns a slice from the list, but the slicing is done by element.
		 * Search is done in a way that if either cmp or equals is true to an element, its position will be chosen
		 * for the slice.
	 	 */
		SortedList!(E, cmp, allowDuplicates, equal) sliceByElem(E from, E to) @safe pure {
			size_t f, t = _array.length;
			E a = from;
			foreach_reverse(size_t i ,E b; _array) {
				if(binaryFun!cmp(a,b) || binaryFun!equal(a,b)){ 
					f = i;
					break;
				}
			}
			a = to;
			foreach_reverse(size_t i ,E b; _array) {
				if(binaryFun!cmp(a,b) || binaryFun!equal(a,b)){ 
					t = i;
					break;
				}
			}
			return opSlice(f, t);
		}
		/**
		 * Set operators.
		 * Enables math operations on sets, like unions and intersections.
		 * Could work on ranges in general as long as they implement some basic functions, like iteration.
		 */
		SortedList!(E, cmp, allowDuplicates, equal) opBinary(string op, R)(R rhs) {
			static if(op == "|" || op == "~") {//Union
				SortedList!(E, cmp, allowDuplicates, equal) result;
				result.end = this.end;
				result._array = this._array.dup;
				foreach(e ; rhs){
					result.put(e);
				}
				return result;
			} else static if(op == "&" || op == "*") {//Intersection
				SortedList!(E, cmp, allowDuplicates, equal) result;
				foreach(e ; rhs){
					if(this.has(e)) result.put(e);
				}
				return result;
			} else static if(op == "-" || op == "/") {//Complement
				SortedList!(E, cmp, allowDuplicates, equal) result = SortedList!(E, cmp, allowDuplicates, equal)(this);
				foreach(e ; rhs){
					result.removeByElem(e);
				}
				return result;
			} else static if(op == "^"){//Difference
				SortedList!(E, cmp, allowDuplicates, equal) result = this | rhs;
				SortedList!(E, cmp, allowDuplicates, equal) common = this & rhs;
				foreach(e ; common){
					result.removeByElem(e);
				}
				return result;
			} else static assert(0, "Operator " ~ op ~ "not supported");
		}
		/**
		 * Set operators.
		 */
		SortedList!(E, cmp, allowDuplicates, equal) opOpAssign(string op)(E value) {
			static if(op == "~=") {//Append
				put(value);
			} else static if(op == "-=" || op == "/=") {
				removeByElem(value);
			} else static assert(0, "Operator " ~ op ~ "not supported");
			return this;
		}
		/**
		 * Set operators.
		 */
		SortedList!(E, cmp, allowDuplicates, equal) opOpAssign(string op, R)(R range) {
			static if(op == "~=" || op == "|=") {//Append
				foreach(val; range)
					put(val);
			} else static if(op == "-=" || op == "/=") {
				foreach(val; range)
					removeByElem(val);
			} else static assert(0, "Operator " ~ op ~ "not supported");
			return this;
		}
	}
	/**
	 * Returns a copy of this struct.
	 */
	@property auto save() @nogc @safe nothrow pure {
		return this;
	}
	/**
	 * Returns the element at the front.
	 */
	@property E front() @nogc @safe nothrow pure {
		return _array[begin];
	}
	/+/**
	 * Returns the element at the front.
	 */
	@property ref E frontRef() @nogc @safe nothrow pure {
		return _array[begin];
	}+/
	/**
	 * Returns the element at the back.
	 */
	@property E back() @nogc @safe nothrow pure {
		return _array[end - 1];
	}
	/+/**
	 * Returns the element at the back.
	 */
	@property ref E backRef() @nogc @safe nothrow pure {
		return _array[end - 1];
	}+/
	/**
	 * Returns the element at begin and increments the position by one.
	 */
	E moveFront() @nogc @safe nothrow pure {
		E result = _array[begin];
		popFront();
		return result;
	}
	/**
	 * Increments the front iteration position by one
	 */
	void popFront() @nogc @safe nothrow pure {
		if(begin < end) begin++;
	}
	/**
	 * Decrements the back iteration position by one
	 */
	void popBack() @nogc @safe nothrow pure {
		if(begin < end) end--;
	}
	/**
	 * Returns true when the end of the list have been reached.
	 */
	@property bool empty() @nogc @safe nothrow pure {
		return begin == end;
	}
	/**
	 * Returns the n-th element.
	 */
	E opIndex(size_t n) @nogc @safe nothrow pure {
		return _array[n];
	}
	/**
	 * Moves to the n-th position and returns the element of that position.
	 */
	E moveAt(size_t n) @nogc @safe nothrow pure {
		begin = n;
		return _array[begin];
	}
	/**
	 * Returns the length of the list.
	 */
	@property size_t length() @nogc @safe nothrow pure {
		return _array.length;
	}
	alias opDollar = length;
	/**
	 * Sets the reserve of the underlying array and returns the current reserve.
	 */
	@property size_t reserve(size_t amount) @safe pure nothrow {
		return _array.reserve(amount);
	}
	/**
	 * Returns a slice from the list.
	 */
	SortedList!(E, cmp, allowDuplicates, equal) opSlice(size_t i0, size_t i1) @safe nothrow pure {
		return SortedList!(E, cmp, allowDuplicates, equal)(_array[i0..i1]);
	}
	
	string toString() {
		import std.conv : to;
		return to!string(_array);
	}
}