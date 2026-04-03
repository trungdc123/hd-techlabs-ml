Task ID: 312

Git Repo: https://github.com/sympy/sympy
Git PR: https://github.com/sympy/sympy/pull/366
PR URL with diff: https://github.com/sympy/sympy/pull/366.diff

Context:
The diff below was fetched locally from the GitHub API using:
Accept: application/vnd.github.v3.diff

This is intended to avoid truncation issues from the browser-facing .diff URL.

Instructions:
Please perform STEP 1 only, following the project master prompt.

Important:
- Base your reasoning strictly on the diff below.
- Do not assume access to the full repository source.
- If the diff is insufficient to determine WHERE or HOW clearly, explicitly say what is still unclear instead of guessing.
- The Turn-1 prompt must be self-contained and must not defer core implementation details to later turns.

Goal:
Produce:
- Repo Definition
- Problem Definition
- Edge Cases
- Acceptance Criteria
- Initial Prompt (Turn 1, fully self-contained)

Self-check before finalizing:
- Can the task be implemented using only this prompt?
- Are WHERE (files/functions) and HOW (strategy) clearly defined?
- Are any requirements implicitly deferred to later turns?

Diff changes:
~~~diff
diff --git a/sympy/assumptions/ask.py b/sympy/assumptions/ask.py
index 36c89d8ef418..056b3f459b06 100644
--- a/sympy/assumptions/ask.py
+++ b/sympy/assumptions/ask.py
@@ -3,9 +3,9 @@
 from sympy.core import sympify
 from sympy.utilities.source import get_class
 from sympy.assumptions import global_assumptions, Predicate
-from sympy.assumptions.assume import eliminate_assume
 from sympy.logic.boolalg import to_cnf, And, Not, Or, Implies, Equivalent
 from sympy.logic.inference import satisfiable
+from sympy.assumptions.assume import AppliedPredicate
 
 class Q:
     """Supported ask keys."""
@@ -61,7 +61,21 @@ def eval_predicate(predicate, expr, assumptions=True):
     return res
 
 
-def ask(expr, key=Q.is_true, assumptions=True, context=global_assumptions, disable_preprocessing=False):
+def _extract_facts(expr, symbol):
+    """
+    Helper for ask().
+
+    Extracts the facts relevant to the symbol from an assumption.
+    Returns None if there is nothing to extract.
+    """
+    if not expr.has(symbol):
+        return None
+    if isinstance(expr, AppliedPredicate):
+        return expr.func
+    return expr.func(*filter(lambda x: x is not None,
+                [_extract_facts(arg, symbol) for arg in expr.args]))
+
+def ask(expr, key=Q.is_true, assumptions=True, context=global_assumptions):
     """
     Method for inferring properties about objects.
 
@@ -92,15 +106,12 @@ def ask(expr, key=Q.is_true, assumptions=True, context=global_assumptions, disab
 
     """
     expr = sympify(expr)
-    if isinstance(key, basestring):
-        key = getattr(Q, str(key))
     assumptions = And(assumptions, And(*context))
 
     # direct resolution method, no logic
-    if not disable_preprocessing:
-        res = eval_predicate(key, expr, assumptions)
-        if res is not None:
-            return res
+    res = eval_predicate(key, expr, assumptions)
+    if res is not None:
+        return res
 
     if assumptions is True:
         return
@@ -108,60 +119,64 @@ def ask(expr, key=Q.is_true, assumptions=True, context=global_assumptions, disab
     if not expr.is_Atom:
         return
 
-    assumptions = eliminate_assume(assumptions, expr)
-    if assumptions is None or assumptions is True:
+    local_facts = _extract_facts(assumptions, expr)
+    if local_facts is None or local_facts is True:
         return
 
     # See if there's a straight-forward conclusion we can make for the inference
-    if not disable_preprocessing:
-        if assumptions.is_Atom:
-            if key in known_facts_dict[assumptions]:
-                return True
-            if Not(key) in known_facts_dict[assumptions]:
-                return False
-        elif assumptions.func is And:
-            for assum in assumptions.args:
-                if assum.is_Atom:
-                    if key in known_facts_dict[assum]:
-                        return True
-                    if Not(key) in known_facts_dict[assum]:
-                        return False
-                elif assum.func is Not and assum.args[0].is_Atom:
-                    if key in known_facts_dict[assum]:
-                        return False
-                    if Not(key) in known_facts_dict[assum]:
-                        return True
-        elif (isinstance(key, Predicate) and
-                assumptions.func is Not and assumptions.args[0].is_Atom):
-            if assumptions.args[0] in known_facts_dict[key]:
-                return False
+    if local_facts.is_Atom:
+        if key in known_facts_dict[local_facts]:
+            return True
+        if Not(key) in known_facts_dict[local_facts]:
+            return False
+    elif local_facts.func is And:
+        for assum in local_facts.args:
+            if assum.is_Atom:
+                if key in known_facts_dict[assum]:
+                    return True
+                if Not(key) in known_facts_dict[assum]:
+                    return False
+            elif assum.func is Not and assum.args[0].is_Atom:
+                if key in known_facts_dict[assum]:
+                    return False
+                if Not(key) in known_facts_dict[assum]:
+                    return True
+    elif (isinstance(key, Predicate) and
+            local_facts.func is Not and local_facts.args[0].is_Atom):
+        if local_facts.args[0] in known_facts_dict[key]:
+            return False
 
     # Failing all else, we do a full logical inference
-    # If it's not consistent with the assumptions, then it can't be true
-    if not satisfiable(And(known_facts_cnf, assumptions, key)):
-        return False
+    return ask_full_inference(key, local_facts)
 
-    # If the negation is unsatisfiable, it is entailed
-    if not satisfiable(And(known_facts_cnf, assumptions, Not(key))):
-        return True
 
-    # Otherwise, we don't have enough information to conclude one way or the other
+def ask_full_inference(proposition, assumptions):
+    """
+    Method for inferring properties about objects.
+
+    """
+    if not satisfiable(And(known_facts_cnf, assumptions, proposition)):
+        return False
+    if not satisfiable(And(known_facts_cnf, assumptions, Not(proposition))):
+        return True
     return None
 
+
+
 def register_handler(key, handler):
     """Register a handler in the ask system. key must be a string and handler a
     class inheriting from AskHandler.
 
-        >>> from sympy.assumptions import register_handler, ask
+        >>> from sympy.assumptions import register_handler, ask, Q
         >>> from sympy.assumptions.handlers import AskHandler
         >>> class MersenneHandler(AskHandler):
         ...     # Mersenne numbers are in the form 2**n + 1, n integer
         ...     @staticmethod
         ...     def Integer(expr, assumptions):
         ...         import math
-        ...         return ask(math.log(expr + 1, 2), 'integer')
+        ...         return ask(math.log(expr + 1, 2), Q.integer)
         >>> register_handler('mersenne', MersenneHandler)
-        >>> ask(7, 'mersenne')
+        >>> ask(7, Q.mersenne)
         True
 
     """
@@ -190,13 +205,12 @@ def compute_known_facts():
     fact_string += "\n)\n"
 
     # Compute the quick lookup for single facts
-    from sympy.abc import x
     mapping = {}
     for key in known_facts_keys:
         mapping[key] = set([key])
         for other_key in known_facts_keys:
             if other_key != key:
-                if ask(x, other_key, key(x), disable_preprocessing=True):
+                if ask_full_inference(other_key, key):
                     mapping[key].add(other_key)
     fact_string += "\n# -{ Known facts in compressed sets }-\n"
     fact_string += "known_facts_dict = {\n    "
diff --git a/sympy/assumptions/assume.py b/sympy/assumptions/assume.py
index ab6563594cb3..d5c38d5af1ac 100644
--- a/sympy/assumptions/assume.py
+++ b/sympy/assumptions/assume.py
@@ -78,36 +78,6 @@ def __eq__(self, other):
     def __hash__(self):
         return super(AppliedPredicate, self).__hash__()
 
-def eliminate_assume(expr, symbol=None):
-    """
-    Convert an expression with assumptions to an equivalent with all assumptions
-    replaced by symbols.
-
-    Q.integer(x) --> Q.integer
-    ~Q.integer(x) --> ~Q.integer
-
-    Examples:
-        >>> from sympy.assumptions.assume import eliminate_assume
-        >>> from sympy import Q
-        >>> from sympy.abc import x
-        >>> eliminate_assume(Q.positive(x))
-        Q.positive
-        >>> eliminate_assume(~Q.positive(x))
-        Not(Q.positive)
-
-    """
-    if symbol is not None:
-        props = expr.atoms(AppliedPredicate)
-        if props and symbol not in [prop.arg for prop in props]:
-            return
-    if expr.__class__ is AppliedPredicate:
-        if symbol is not None:
-            if not expr.arg.has(symbol):
-                return
-        return expr.func
-    return expr.func(*filter(lambda x: x is not None,
-                [eliminate_assume(arg, symbol) for arg in expr.args]))
-
 class Predicate(Boolean):
     """A predicate is a function that returns a boolean value.
 
diff --git a/sympy/assumptions/handlers/sets.py b/sympy/assumptions/handlers/sets.py
index b0f3c700f76b..6c9483fa0598 100644
--- a/sympy/assumptions/handlers/sets.py
+++ b/sympy/assumptions/handlers/sets.py
@@ -1,12 +1,12 @@
 """
-Handlers for keys related to set membership: integer, rational, etc.
+Handlers for predicates related to set membership: integer, rational, etc.
 """
 from sympy.assumptions import Q, ask
 from sympy.assumptions.handlers import CommonHandler
 
 class AskIntegerHandler(CommonHandler):
     """
-    Handler for key 'integer'
+    Handler for Q.integer
     Test that an expression belongs to the field of integer numbers
     """
 
@@ -26,7 +26,7 @@ def Add(expr, assumptions):
         """
         if expr.is_number:
             return AskIntegerHandler._number(expr, assumptions)
-        return test_closed_group(expr, assumptions, 'integer')
+        return test_closed_group(expr, assumptions, Q.integer)
 
     @staticmethod
     def Mul(expr, assumptions):
@@ -102,7 +102,7 @@ def Abs(expr, assumptions):
 
 class AskRationalHandler(CommonHandler):
     """
-    Handler for key 'rational'
+    Handler for Q.rational
     Test that an expression belongs to the field of rational numbers
     """
 
@@ -116,7 +116,7 @@ def Add(expr, assumptions):
         if expr.is_number:
             if expr.as_real_imag()[1]:
                 return False
-        return test_closed_group(expr, assumptions, 'rational')
+        return test_closed_group(expr, assumptions, Q.rational)
 
     Mul = Add
 
@@ -175,7 +175,7 @@ def Basic(expr, assumptions):
 
 class AskRealHandler(CommonHandler):
     """
-    Handler for key 'real'
+    Handler for Q.real
     Test that an expression belongs to the field of real numbers
     """
 
@@ -191,7 +191,7 @@ def Add(expr, assumptions):
         """
         if expr.is_number:
             return AskRealHandler._number(expr, assumptions)
-        return test_closed_group(expr, assumptions, 'real')
+        return test_closed_group(expr, assumptions, Q.real)
 
     @staticmethod
     def Mul(expr, assumptions):
@@ -282,14 +282,14 @@ def sin(expr, assumptions):
 
 class AskExtendedRealHandler(AskRealHandler):
     """
-    Handler for key 'extended_real'
+    Handler for Q.extended_real
     Test that an expression belongs to the field of extended real numbers,
     that is real numbers union {Infinity, -Infinity}
     """
 
     @staticmethod
     def Add(expr, assumptions):
-        return test_closed_group(expr, assumptions, 'extended_real')
+        return test_closed_group(expr, assumptions, Q.extended_real)
 
     Mul, Pow = Add, Add
 
@@ -303,13 +303,13 @@ def NegativeInfinity(expr, assumptions):
 
 class AskComplexHandler(CommonHandler):
     """
-    Handler for key 'complex'
+    Handler for Q.complex
     Test that an expression belongs to the field of complex numbers
     """
 
     @staticmethod
     def Add(expr, assumptions):
-        return test_closed_group(expr, assumptions, 'complex')
+        return test_closed_group(expr, assumptions, Q.complex)
 
     Mul, Pow = Add, Add
 
@@ -341,7 +341,7 @@ def NegativeInfinity(expr, assumptions):
 
 class AskImaginaryHandler(CommonHandler):
     """
-    Handler for key 'imaginary'
+    Handler for Q.imaginary
     Test that an expression belongs to the field of imaginary numbers,
     that is, numbers in the form x*I, where x is real
     """
@@ -408,19 +408,19 @@ def ImaginaryUnit(expr, assumptions):
         return True
 
 class AskAlgebraicHandler(CommonHandler):
-    """Handler for 'algebraic' key. """
+    """Handler for Q.algebraic key. """
 
     @staticmethod
     def Add(expr, assumptions):
-        return test_closed_group(expr, assumptions, 'algebraic')
+        return test_closed_group(expr, assumptions, Q.algebraic)
 
     @staticmethod
     def Mul(expr, assumptions):
-        return test_closed_group(expr, assumptions, 'algebraic')
+        return test_closed_group(expr, assumptions, Q.algebraic)
 
     @staticmethod
     def Pow(expr, assumptions):
-        return expr.exp.is_Rational and ask(expr.base, 'algebraic', assumptions)
+        return expr.exp.is_Rational and ask(expr.base, Q.algebraic, assumptions)
 
     @staticmethod
     def Number(expr, assumptions):
diff --git a/sympy/assumptions/tests/test_assumptions_2.py b/sympy/assumptions/tests/test_assumptions_2.py
index c89c85566241..50348cb22f5e 100644
--- a/sympy/assumptions/tests/test_assumptions_2.py
+++ b/sympy/assumptions/tests/test_assumptions_2.py
@@ -1,7 +1,7 @@
 """rename this to test_assumptions.py when the old assumptions system is deleted"""
 from sympy.core import symbols
 from sympy.assumptions import AppliedPredicate, global_assumptions, Predicate
-from sympy.assumptions.assume import eliminate_assume
+from sympy.assumptions.ask import _extract_facts
 from sympy.printing import pretty
 from sympy.assumptions.ask import Q
 from sympy.logic.boolalg import Or
@@ -18,21 +18,15 @@ def test_pretty():
     x = symbols('x')
     assert pretty(Q.positive(x)) == "Q.positive(x)"
 
-def test_eliminate_assumptions():
+def test_extract_facts():
     a, b = symbols('a b', cls=Predicate)
     x, y = symbols('x y')
-    assert eliminate_assume(a(x))  == a
-    assert eliminate_assume(a(x), symbol=x)  == a
-    assert eliminate_assume(a(x), symbol=y)  == None
-    assert eliminate_assume(~a(x)) == ~a
-    assert eliminate_assume(a(x), symbol=y) == None
-    assert eliminate_assume(a(x) | b(x)) == a | b
-    assert eliminate_assume(a(x) | ~b(x)) == a | ~b
-
-def test_eliminate_composite_assumptions():
-    a, b = map(Predicate, symbols('a b'))
-    x, y = symbols('x y')
-    assert eliminate_assume(~a(y), x) == None
+    assert _extract_facts(a(x), x)  == a
+    assert _extract_facts(a(x), y)  == None
+    assert _extract_facts(~a(x), x) == ~a
+    assert _extract_facts(~a(x), y) == None
+    assert _extract_facts(a(x) | b(x), x) == a | b
+    assert _extract_facts(a(x) | ~b(x), x) == a | ~b
 
 def test_global():
     """Test for global assumptions"""
diff --git a/sympy/assumptions/tests/test_query.py b/sympy/assumptions/tests/test_query.py
index 5c6a949c4f04..30d0472a6823 100644
--- a/sympy/assumptions/tests/test_query.py
+++ b/sympy/assumptions/tests/test_query.py
@@ -879,30 +879,30 @@ def test_real():
 def test_algebraic():
     x, y = symbols('x,y')
 
-    assert ask(x, 'algebraic') == None
+    assert ask(x, Q.algebraic) == None
 
-    assert ask(I, 'algebraic') == True
-    assert ask(2*I, 'algebraic') == True
-    assert ask(I/3, 'algebraic') == True
+    assert ask(I, Q.algebraic) == True
+    assert ask(2*I, Q.algebraic) == True
+    assert ask(I/3, Q.algebraic) == True
 
-    assert ask(sqrt(7), 'algebraic') == True
-    assert ask(2*sqrt(7), 'algebraic') == True
-    assert ask(sqrt(7)/3, 'algebraic') == True
+    assert ask(sqrt(7), Q.algebraic) == True
+    assert ask(2*sqrt(7), Q.algebraic) == True
+    assert ask(sqrt(7)/3, Q.algebraic) == True
 
-    assert ask(I*sqrt(3), 'algebraic') == True
-    assert ask(sqrt(1+I*sqrt(3)), 'algebraic') == True
+    assert ask(I*sqrt(3), Q.algebraic) == True
+    assert ask(sqrt(1+I*sqrt(3)), Q.algebraic) == True
 
-    assert ask((1+I*sqrt(3)**(S(17)/31)), 'algebraic') == True
-    assert ask((1+I*sqrt(3)**(S(17)/pi)), 'algebraic') == False
+    assert ask((1+I*sqrt(3)**(S(17)/31)), Q.algebraic) == True
+    assert ask((1+I*sqrt(3)**(S(17)/pi)), Q.algebraic) == False
 
-    assert ask(sin(7), 'algebraic') == None
-    assert ask(sqrt(sin(7)), 'algebraic') == None
-    assert ask(sqrt(y+I*sqrt(7)), 'algebraic') == None
+    assert ask(sin(7), Q.algebraic) == None
+    assert ask(sqrt(sin(7)), Q.algebraic) == None
+    assert ask(sqrt(y+I*sqrt(7)), Q.algebraic) == None
 
-    assert ask(oo, 'algebraic') == False
-    assert ask(-oo, 'algebraic') == False
+    assert ask(oo, Q.algebraic) == False
+    assert ask(-oo, Q.algebraic) == False
 
-    assert ask(2.47, 'algebraic') == False
+    assert ask(2.47, Q.algebraic) == False
 
 def test_global():
     """Test ask with global assumptions"""
@@ -972,15 +972,15 @@ def Number(expr, assumptions):
 def test_key_extensibility():
     """test that you can add keys to the ask system at runtime"""
     x = Symbol('x')
-    # make sure thie key is not defined
-    raises(AttributeError, "ask(x, 'my_key')")
+    # make sure the key is not defined
+    raises(AttributeError, "ask(x, Q.my_key)")
     class MyAskHandler(AskHandler):
         @staticmethod
         def Symbol(expr, assumptions):
             return True
     register_handler('my_key', MyAskHandler)
-    assert ask(x, 'my_key') == True
-    assert ask(x+1, 'my_key') == None
+    assert ask(x, Q.my_key) == True
+    assert ask(x+1, Q.my_key) == None
     remove_handler('my_key', MyAskHandler)
 
 def test_type_extensibility():
diff --git a/sympy/polys/constructor.py b/sympy/polys/constructor.py
index 6f308a47144d..97df10876af5 100644
--- a/sympy/polys/constructor.py
+++ b/sympy/polys/constructor.py
@@ -3,7 +3,7 @@
 from sympy.polys.polyutils import parallel_dict_from_basic
 from sympy.polys.polyoptions import build_options
 from sympy.polys.domains import ZZ, QQ, RR, EX
-from sympy.assumptions import ask
+from sympy.assumptions import ask, Q
 from sympy.core import S, sympify
 from sympy.utilities import any
 
@@ -12,7 +12,7 @@ def _construct_simple(coeffs, opt):
     result, rationals, reals, algebraics = {}, False, False, False
 
     if opt.extension is True:
-        is_algebraic = lambda coeff: ask(coeff, 'algebraic')
+        is_algebraic = lambda coeff: ask(coeff, Q.algebraic)
     else:
         is_algebraic = lambda coeff: False
 
diff --git a/sympy/polys/polyutils.py b/sympy/polys/polyutils.py
index e5ea3a623e67..b47ec31b1ebd 100644
--- a/sympy/polys/polyutils.py
+++ b/sympy/polys/polyutils.py
@@ -6,7 +6,7 @@
 from sympy.core.exprtools import decompose_power
 
 from sympy.core import S, Add, Mul, Pow
-from sympy.assumptions import ask
+from sympy.assumptions import ask, Q
 from sympy.utilities import any
 
 import re
@@ -177,7 +177,7 @@ def _is_coeff(factor):
             return factor in opt.domain
     elif opt.extension is True:
         def _is_coeff(factor):
-            return ask(factor, 'algebraic')
+            return ask(factor, Q.algebraic)
     elif opt.greedy is not False:
         def _is_coeff(factor):
             return False
diff --git a/sympy/solvers/inequalities.py b/sympy/solvers/inequalities.py
index 77f464936b18..8294387cfd69 100644
--- a/sympy/solvers/inequalities.py
+++ b/sympy/solvers/inequalities.py
@@ -3,7 +3,7 @@
 from sympy.core import Symbol, Interval, Union
 from sympy.core.relational import Relational, Eq, Ge, Lt
 from sympy.core.singleton import S
-from sympy.assumptions import ask, AppliedPredicate
+from sympy.assumptions import ask, AppliedPredicate, Q
 from sympy.functions import re, im, Abs
 from sympy.logic import And, Or
 from sympy.polys import Poly
@@ -146,7 +146,7 @@ def reduce_poly_inequalities(exprs, gen, assume=True, relational=True):
     if not relational:
         return intervals
 
-    real = ask(gen, 'real', assume)
+    real = ask(Q.real(gen), assumptions=assume)
 
     def relationalize(gen):
         return Or(*[ i.as_relational(gen) for i in intervals ])
@@ -160,7 +160,7 @@ def relationalize(gen):
 
 def reduce_abs_inequality(expr, rel, gen, assume=True):
     """Reduce an inequality with nested absolute values. """
-    if not ask(gen, 'real', assume):
+    if not ask(Q.real(gen), assumptions=assume):
         raise NotImplementedError("can't solve inequalities with absolute values of a complex variable")
 
     def bottom_up_scan(expr):

~~~
