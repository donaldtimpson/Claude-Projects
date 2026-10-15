## Test 1 — Linear Equations in Linear Algebra (Chapter 1)

*Unit test · 100 points core + 5 points extra credit · time 90 minutes. No calculator. Show all reasoning; partial credit is given. Justify every "yes/no" answer with a theorem, a computation, or a counterexample.*

---

**1. Row Reduction (12 points).** Consider the system

$$\begin{aligned} x_1 + 2x_2 - x_3 + 3x_4 &= 4 \\ 2x_1 + 4x_2 - x_3 + 7x_4 &= 9 \\ -x_1 - 2x_2 + 3x_3 - x_4 &= -2 \end{aligned}$$

(a) (6 pts) Write the augmented matrix and row reduce it to **reduced** echelon form.

(b) (2 pts) Identify the pivot columns, the basic variables, and the free variables.

(c) (4 pts) Write the general solution, solving for the basic variables in terms of the free variables.

**2. Existence & Uniqueness (8 points).** Consider the system

$$\begin{aligned} x_1 + 2x_2 + x_3 &= 1 \\ 2x_1 + 5x_2 + 3x_3 &= 4 \\ x_1 + 3x_2 + hx_3 &= k \end{aligned}$$

Find all values of $h$ and $k$ for which the system has

(a) (3 pts) a unique solution;

(b) (3 pts) no solution;

(c) (2 pts) infinitely many solutions.

**3. Span (10 points).** Let $\mathbf a_1=\begin{bmatrix}1\\2\\-1\end{bmatrix}$, $\mathbf a_2=\begin{bmatrix}-2\\-3\\4\end{bmatrix}$, $\mathbf a_3=\begin{bmatrix}3\\8\\1\end{bmatrix}$, and let $A=[\,\mathbf a_1\ \mathbf a_2\ \mathbf a_3\,]$.

(a) (5 pts) Find the condition on $b_1,b_2,b_3$ for $\mathbf b=\begin{bmatrix}b_1\\b_2\\b_3\end{bmatrix}$ to lie in $\operatorname{Span}\{\mathbf a_1,\mathbf a_2,\mathbf a_3\}$.

(b) (3 pts) Is $\mathbf b=\begin{bmatrix}1\\4\\3\end{bmatrix}$ in $\operatorname{Span}\{\mathbf a_1,\mathbf a_2,\mathbf a_3\}$? If so, write $\mathbf b$ as a linear combination of $\mathbf a_1,\mathbf a_2,\mathbf a_3$.

(c) (2 pts) Do the columns of $A$ span $\mathbb R^3$? Justify.

**4. Solution Sets (12 points).** Let $A=\begin{bmatrix}1&3&-2&1\\2&6&-3&5\\-1&-3&4&3\end{bmatrix}$ and $\mathbf b=\begin{bmatrix}2\\7\\4\end{bmatrix}$.

(a) (5 pts) Write the solution set of $A\mathbf x=\mathbf 0$ in parametric vector form.

(b) (5 pts) Write the solution set of $A\mathbf x=\mathbf b$ in parametric vector form.

(c) (2 pts) Describe both solution sets geometrically and say how they are related.

**5. Linear Independence (10 points).** Let $\mathbf v_1=\begin{bmatrix}1\\-1\\2\end{bmatrix}$, $\mathbf v_2=\begin{bmatrix}2\\1\\1\end{bmatrix}$, $\mathbf v_3=\begin{bmatrix}3\\h\\7\end{bmatrix}$.

(a) (5 pts) Find all values of $h$ for which $\{\mathbf v_1,\mathbf v_2,\mathbf v_3\}$ is linearly dependent.

(b) (5 pts) For that value of $h$, find a linear dependence relation among $\mathbf v_1,\mathbf v_2,\mathbf v_3$ with integer weights.

**6. Balancing a Chemical Equation (6 points).** Pentane burns in oxygen:

$$x_1\,\mathrm{C_5H_{12}} + x_2\,\mathrm{O_2} \;\to\; x_3\,\mathrm{CO_2} + x_4\,\mathrm{H_2O}$$

Set up the vector equation (one vector per molecule, counting C, H, O), solve the resulting homogeneous system, and give the balanced equation with the smallest positive whole-number coefficients.

**7. The Matrix of a Linear Transformation (12 points).**

(a) (5 pts) Let $T:\mathbb R^2\to\mathbb R^2$ first rotate points counterclockwise through $\pi/2$ radians and then reflect them through the $x_1$-axis. Find the standard matrix of $T$.

(b) (2 pts) $T$ is a single familiar geometric transformation. Which one?

(c) (5 pts) Let $S:\mathbb R^2\to\mathbb R^3$ be a linear transformation with $S\!\left(\begin{bmatrix}1\\1\end{bmatrix}\right)=\begin{bmatrix}1\\0\\2\end{bmatrix}$ and $S\!\left(\begin{bmatrix}1\\-1\end{bmatrix}\right)=\begin{bmatrix}3\\2\\0\end{bmatrix}$. Find the standard matrix of $S$.

**8. One-to-One & Onto (10 points).** Let $T:\mathbb R^3\to\mathbb R^3$ be defined by

$$T(x_1,x_2,x_3)=(x_1-x_2+2x_3,\;\;2x_2+x_3,\;\;3x_1-x_2+7x_3).$$

(a) (2 pts) Find the standard matrix $A$ of $T$.

(b) (4 pts) Is $T$ one-to-one? Justify. If not, find a nonzero $\mathbf x$ with $T(\mathbf x)=\mathbf 0$.

(c) (4 pts) Does $T$ map $\mathbb R^3$ onto $\mathbb R^3$? Justify.

**9. True or False (12 points, 2 each).** State whether each statement is true or false, and justify: cite a theorem or definition if true, give a counterexample if false.

(a) A linear system with more variables than equations has infinitely many solutions.

(b) If $A$ is a $3\times5$ matrix, then the columns of $A$ are linearly dependent.

(c) If the columns of an $m\times n$ matrix $A$ span $\mathbb R^m$, then $A\mathbf x=\mathbf b$ is consistent for every $\mathbf b$ in $\mathbb R^m$.

(d) If $\mathbf x$ is a nontrivial solution of $A\mathbf x=\mathbf 0$, then every entry of $\mathbf x$ is nonzero.

(e) Every linear transformation $T:\mathbb R^n\to\mathbb R^m$ satisfies $T(\mathbf 0)=\mathbf 0$.

(f) If $\{\mathbf v_1,\mathbf v_2,\mathbf v_3\}$ is linearly dependent, then $\mathbf v_3$ is a linear combination of $\mathbf v_1$ and $\mathbf v_2$.

**10. Proofs (8 points).**

(a) (4 pts) Let $A$ be an $m\times n$ matrix. Prove that if $\mathbf u$ and $\mathbf v$ are solutions of $A\mathbf x=\mathbf 0$, then $c\mathbf u+d\mathbf v$ is also a solution for all scalars $c,d$.

(b) (4 pts) Let $T:\mathbb R^n\to\mathbb R^m$ be linear. Prove that if $\{T(\mathbf v_1),T(\mathbf v_2),T(\mathbf v_3)\}$ is linearly independent, then $\{\mathbf v_1,\mathbf v_2,\mathbf v_3\}$ is linearly independent.

### Extra Credit (5 points ••)

Let $A$ be an $n\times n$ matrix. Prove that the columns of $A$ span $\mathbb R^n$ **if and only if** the columns of $A$ are linearly independent.

<!-- SOLUTIONS -->

## Answer Key — Test 1

**1.** (a) Augmented matrix and row reduction ($R_2-2R_1$, $R_3+R_1$, then $R_3-2R_2$, then $R_1+R_2$):

$$\begin{bmatrix}1&2&-1&3&4\\2&4&-1&7&9\\-1&-2&3&-1&-2\end{bmatrix}\sim\begin{bmatrix}1&2&-1&3&4\\0&0&1&1&1\\0&0&2&2&2\end{bmatrix}\sim\begin{bmatrix}1&2&0&4&5\\0&0&1&1&1\\0&0&0&0&0\end{bmatrix}$$

(b) Pivot columns 1 and 3. Basic variables $x_1,x_3$; free variables $x_2,x_4$.

(c) $x_1=5-2x_2-4x_4$, $\;x_2$ free, $\;x_3=1-x_4$, $\;x_4$ free.

**2.** Row reduce ($R_2-2R_1$, $R_3-R_1$, then $R_3-R_2$):

$$\begin{bmatrix}1&2&1&1\\2&5&3&4\\1&3&h&k\end{bmatrix}\sim\begin{bmatrix}1&2&1&1\\0&1&1&2\\0&0&h-2&k-3\end{bmatrix}$$

(a) Unique solution iff there is a pivot in every coefficient column: $h\neq2$ ($k$ arbitrary).

(b) No solution iff the last row is $[\,0\ 0\ 0\ \ c\,]$ with $c\ne0$: $h=2$ and $k\neq3$.

(c) Infinitely many iff the last row is all zeros: $h=2$ and $k=3$ ($x_3$ is then free).

**3.** (a) Row reduce $[\,A\ \ \mathbf b\,]$ ($R_2-2R_1$, $R_3+R_1$, then $R_3-2R_2$):

$$\begin{bmatrix}1&-2&3&b_1\\2&-3&8&b_2\\-1&4&1&b_3\end{bmatrix}\sim\begin{bmatrix}1&-2&3&b_1\\0&1&2&b_2-2b_1\\0&0&0&5b_1-2b_2+b_3\end{bmatrix}$$

$\mathbf b$ is in the span iff the system is consistent, i.e. iff $5b_1-2b_2+b_3=0$.

(b) $5(1)-2(4)+3=0$, so yes. The reduced form is $x_1=5-7x_3$, $x_2=2-2x_3$; taking $x_3=0$: $\mathbf b=5\mathbf a_1+2\mathbf a_2+0\,\mathbf a_3$. Check: $5(1,2,-1)+2(-2,-3,4)=(1,4,3)$. (Any $x_3$ gives a valid combination.)

(c) No. The echelon form has no pivot in row 3, so by Theorem 4, $A\mathbf x=\mathbf b$ is not consistent for every $\mathbf b$; e.g. $\mathbf b=(0,0,1)$ fails the condition in (a).

**4.** (a) $[\,A\ \ \mathbf 0\,]$ reduces to $\begin{bmatrix}1&3&0&0&0\\0&0&1&0&0\\0&0&0&1&0\end{bmatrix}$, so $x_1=-3x_2$, $x_3=0$, $x_4=0$, $x_2$ free:

$$\mathbf x=x_2\begin{bmatrix}-3\\1\\0\\0\end{bmatrix}.$$

(b) $[\,A\ \ \mathbf b\,]$ reduces to $\begin{bmatrix}1&3&0&0&8\\0&0&1&0&3\\0&0&0&1&0\end{bmatrix}$, so $x_1=8-3x_2$, $x_3=3$, $x_4=0$:

$$\mathbf x=\begin{bmatrix}8\\0\\3\\0\end{bmatrix}+x_2\begin{bmatrix}-3\\1\\0\\0\end{bmatrix}.$$

(c) The solution set of $A\mathbf x=\mathbf 0$ is the line through the origin spanned by $(-3,1,0,0)$ in $\mathbb R^4$. The solution set of $A\mathbf x=\mathbf b$ is the parallel line through $\mathbf p=(8,0,3,0)$: it is the homogeneous solution set translated by the particular solution $\mathbf p$ (Theorem 6).

**5.** (a) Row reduce $[\,\mathbf v_1\ \mathbf v_2\ \mathbf v_3\,]$ ($R_2+R_1$, $R_3-2R_1$, then $R_3+R_2$):

$$\begin{bmatrix}1&2&3\\-1&1&h\\2&1&7\end{bmatrix}\sim\begin{bmatrix}1&2&3\\0&3&h+3\\0&-3&1\end{bmatrix}\sim\begin{bmatrix}1&2&3\\0&3&h+3\\0&0&h+4\end{bmatrix}$$

The set is dependent iff there is a free variable, iff $h+4=0$: $h=-4$.

(b) With $h=-4$, the equation $x_1\mathbf v_1+x_2\mathbf v_2+x_3\mathbf v_3=\mathbf 0$ gives $3x_2=x_3$ and $x_1=-2x_2-3x_3$. Take $x_3=3$: $x_2=1$, $x_1=-11$. So

$$-11\mathbf v_1+\mathbf v_2+3\mathbf v_3=\mathbf 0.$$

Check: $-11(1,-1,2)+(2,1,1)+3(3,-4,7)=(0,0,0)$.

**6.** Vectors (C, H, O): $\mathrm{C_5H_{12}}=(5,12,0)$, $\mathrm{O_2}=(0,0,2)$, $\mathrm{CO_2}=(1,0,2)$, $\mathrm{H_2O}=(0,2,1)$. The equation $x_1(5,12,0)+x_2(0,0,2)=x_3(1,0,2)+x_4(0,2,1)$ gives the homogeneous system

$$\begin{bmatrix}5&0&-1&0&0\\12&0&0&-2&0\\0&2&-2&-1&0\end{bmatrix}\sim\begin{bmatrix}1&0&0&-\tfrac16&0\\0&1&0&-\tfrac43&0\\0&0&1&-\tfrac56&0\end{bmatrix}$$

so $x_1=\tfrac16x_4$, $x_2=\tfrac43x_4$, $x_3=\tfrac56x_4$. Taking $x_4=6$:

$$\mathrm{C_5H_{12}}+8\,\mathrm{O_2}\to5\,\mathrm{CO_2}+6\,\mathrm{H_2O}.$$

**7.** (a) Track the basis vectors: rotation by $\pi/2$ sends $\mathbf e_1\mapsto\mathbf e_2$, $\mathbf e_2\mapsto-\mathbf e_1$; reflection through the $x_1$-axis then sends $\mathbf e_2\mapsto-\mathbf e_2$, $-\mathbf e_1\mapsto-\mathbf e_1$. So $T(\mathbf e_1)=-\mathbf e_2$, $T(\mathbf e_2)=-\mathbf e_1$:

$$A=\begin{bmatrix}0&-1\\-1&0\end{bmatrix}.$$

(b) $A(x_1,x_2)=(-x_2,-x_1)$: reflection through the line $x_2=-x_1$.

(c) $\mathbf e_1=\tfrac12\big[(1,1)+(1,-1)\big]$ and $\mathbf e_2=\tfrac12\big[(1,1)-(1,-1)\big]$. By linearity,

$S(\mathbf e_1)=\tfrac12\big[(1,0,2)+(3,2,0)\big]=(2,1,1)$, $\;S(\mathbf e_2)=\tfrac12\big[(1,0,2)-(3,2,0)\big]=(-1,-1,1)$, so

$$[S]=\begin{bmatrix}2&-1\\1&-1\\1&1\end{bmatrix}.$$

**8.** (a) $A=\begin{bmatrix}1&-1&2\\0&2&1\\3&-1&7\end{bmatrix}$.

(b) $A\sim\begin{bmatrix}1&-1&2\\0&2&1\\0&2&1\end{bmatrix}\sim\begin{bmatrix}1&0&\tfrac52\\0&1&\tfrac12\\0&0&0\end{bmatrix}$. Column 3 has no pivot, so $A\mathbf x=\mathbf 0$ has a free variable and a nontrivial solution; by Theorem 11, $T$ is **not** one-to-one. With $x_3=2$: $\mathbf x=(-5,-1,2)$, and $T(-5,-1,2)=(-5+1+4,\;-2+2,\;-15+1+14)=(0,0,0)$.

(c) No. Row 3 of the echelon form has no pivot, so the columns of $A$ do not span $\mathbb R^3$ (Theorem 4), and by Theorem 12, $T$ is **not** onto.

**9.** (a) **False.** The system may be inconsistent: $x_1+x_2+x_3=0$, $x_1+x_2+x_3=1$ has three variables, two equations, and no solution. (If it is consistent, then it has infinitely many solutions.)

(b) **True.** Five vectors in $\mathbb R^3$: more vectors than entries, so they are dependent (Theorem 8). (Equivalently: at most 3 pivots, so at least 2 free variables.)

(c) **True.** This is one of the equivalent statements of Theorem 4.

(d) **False.** $A=\begin{bmatrix}1&0\\0&0\end{bmatrix}$ has the nontrivial solution $\mathbf x=(0,1)$, which has a zero entry.

(e) **True.** $T(\mathbf 0)=T(0\cdot\mathbf 0)=0\cdot T(\mathbf 0)=\mathbf 0$.

(f) **False.** $\mathbf v_1=(1,0)$, $\mathbf v_2=(2,0)$, $\mathbf v_3=(0,1)$: the set is dependent because $\mathbf v_2=2\mathbf v_1$, but $\mathbf v_3$ is not a combination of $\mathbf v_1,\mathbf v_2$. (Theorem 7 only guarantees that *some* vector is a linear combination of the others — not that every one is, and not necessarily $\mathbf v_3$.)

**10.** (a) Given $A\mathbf u=\mathbf 0$ and $A\mathbf v=\mathbf 0$. By the linearity of the matrix-vector product (Theorem 5),

$$A(c\mathbf u+d\mathbf v)=cA\mathbf u+dA\mathbf v=c\mathbf 0+d\mathbf 0=\mathbf 0.$$

(b) Suppose $c_1\mathbf v_1+c_2\mathbf v_2+c_3\mathbf v_3=\mathbf 0$. Apply $T$ and use linearity together with $T(\mathbf 0)=\mathbf 0$:

$$c_1T(\mathbf v_1)+c_2T(\mathbf v_2)+c_3T(\mathbf v_3)=T(c_1\mathbf v_1+c_2\mathbf v_2+c_3\mathbf v_3)=T(\mathbf 0)=\mathbf 0.$$

Since $\{T(\mathbf v_1),T(\mathbf v_2),T(\mathbf v_3)\}$ is linearly independent, $c_1=c_2=c_3=0$. So the only dependence relation among the $\mathbf v_i$ is the trivial one, and $\{\mathbf v_1,\mathbf v_2,\mathbf v_3\}$ is linearly independent.

### Extra Credit

Let $U$ be an echelon form of $A$. Since $A$ is $n\times n$, $U$ has $n$ rows and $n$ columns, and each pivot occupies exactly one row and exactly one column. Let $p$ be the number of pivots. Then:

- The columns of $A$ span $\mathbb R^n$ $\iff$ $A$ has a pivot in every row (Theorem 4) $\iff$ $p=n$.
- The columns of $A$ are linearly independent $\iff$ $A\mathbf x=\mathbf 0$ has only the trivial solution $\iff$ there are no free variables $\iff$ every column is a pivot column $\iff$ $p=n$.

Both conditions are equivalent to $p=n$, so they are equivalent to each other. $\blacksquare$
