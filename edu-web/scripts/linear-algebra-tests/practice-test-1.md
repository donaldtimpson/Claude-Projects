## Practice Test 1 — Linear Equations in Linear Algebra (Chapter 1)

*Practice for Test 1 · 100 points core + 5 points extra credit · time 90 minutes. No calculator. Show all reasoning; partial credit is given. Justify every "yes/no" answer with a theorem, a computation, or a counterexample.*

---

**1. Row Reduction (12 points).** Consider the system

$$\begin{aligned} x_1 - 3x_2 + 2x_3 - x_4 &= 2 \\ 3x_1 - 9x_2 + 7x_3 - x_4 &= 8 \\ -2x_1 + 6x_2 - 3x_3 + 4x_4 &= -2 \end{aligned}$$

(a) (6 pts) Write the augmented matrix and row reduce it to **reduced** echelon form.

(b) (2 pts) Identify the pivot columns, the basic variables, and the free variables.

(c) (4 pts) Write the general solution, solving for the basic variables in terms of the free variables.

**2. Existence & Uniqueness (8 points).** Consider the system

$$\begin{aligned} x_1 - x_2 + 2x_3 &= 3 \\ 3x_1 - 2x_2 + 5x_3 &= 7 \\ 2x_1 + x_2 + hx_3 &= k \end{aligned}$$

Find all values of $h$ and $k$ for which the system has

(a) (3 pts) a unique solution;

(b) (3 pts) no solution;

(c) (2 pts) infinitely many solutions.

**3. Span (10 points).** Let $\mathbf a_1=\begin{bmatrix}1\\-2\\3\end{bmatrix}$, $\mathbf a_2=\begin{bmatrix}3\\-5\\7\end{bmatrix}$, $\mathbf a_3=\begin{bmatrix}-1\\4\\-7\end{bmatrix}$, and let $A=[\,\mathbf a_1\ \mathbf a_2\ \mathbf a_3\,]$.

(a) (5 pts) Find the condition on $b_1,b_2,b_3$ for $\mathbf b=\begin{bmatrix}b_1\\b_2\\b_3\end{bmatrix}$ to lie in $\operatorname{Span}\{\mathbf a_1,\mathbf a_2,\mathbf a_3\}$.

(b) (3 pts) Is $\mathbf b=\begin{bmatrix}2\\-3\\4\end{bmatrix}$ in $\operatorname{Span}\{\mathbf a_1,\mathbf a_2,\mathbf a_3\}$? If so, write $\mathbf b$ as a linear combination of $\mathbf a_1,\mathbf a_2,\mathbf a_3$.

(c) (2 pts) Do the columns of $A$ span $\mathbb R^3$? Justify.

**4. Solution Sets (12 points).** Let $A=\begin{bmatrix}1&-2&1&2\\3&-6&4&9\\-2&4&-1&-1\end{bmatrix}$ and $\mathbf b=\begin{bmatrix}1\\5\\0\end{bmatrix}$.

(a) (5 pts) Write the solution set of $A\mathbf x=\mathbf 0$ in parametric vector form.

(b) (5 pts) Write the solution set of $A\mathbf x=\mathbf b$ in parametric vector form.

(c) (2 pts) Describe both solution sets geometrically and say how they are related.

**5. Linear Independence (10 points).** Let $\mathbf v_1=\begin{bmatrix}1\\2\\-1\end{bmatrix}$, $\mathbf v_2=\begin{bmatrix}3\\7\\-2\end{bmatrix}$, $\mathbf v_3=\begin{bmatrix}-1\\h\\4\end{bmatrix}$.

(a) (5 pts) Find all values of $h$ for which $\{\mathbf v_1,\mathbf v_2,\mathbf v_3\}$ is linearly dependent.

(b) (5 pts) For that value of $h$, find a linear dependence relation among $\mathbf v_1,\mathbf v_2,\mathbf v_3$ with integer weights.

**6. Balancing a Chemical Equation (6 points).** Ethane burns in oxygen:

$$x_1\,\mathrm{C_2H_6} + x_2\,\mathrm{O_2} \;\to\; x_3\,\mathrm{CO_2} + x_4\,\mathrm{H_2O}$$

Set up the vector equation (one vector per molecule, counting C, H, O), solve the resulting homogeneous system, and give the balanced equation with the smallest positive whole-number coefficients.

**7. The Matrix of a Linear Transformation (12 points).**

(a) (5 pts) Let $T:\mathbb R^2\to\mathbb R^2$ first rotate points **clockwise** through $\pi/2$ radians and then reflect them through the line $x_2=x_1$. Find the standard matrix of $T$.

(b) (2 pts) $T$ is a single familiar geometric transformation. Which one?

(c) (5 pts) Let $S:\mathbb R^2\to\mathbb R^3$ be a linear transformation with $S\!\left(\begin{bmatrix}1\\2\end{bmatrix}\right)=\begin{bmatrix}3\\0\\5\end{bmatrix}$ and $S\!\left(\begin{bmatrix}0\\1\end{bmatrix}\right)=\begin{bmatrix}1\\-1\\2\end{bmatrix}$. Find the standard matrix of $S$.

**8. One-to-One & Onto (10 points).** Let $T:\mathbb R^3\to\mathbb R^4$ be defined by

$$T(x_1,x_2,x_3)=(x_1+2x_2,\;\;-x_1+x_2+3x_3,\;\;2x_1+x_2-2x_3,\;\;3x_2+4x_3).$$

(a) (2 pts) Find the standard matrix $A$ of $T$.

(b) (4 pts) Is $T$ one-to-one? Justify.

(c) (4 pts) Does $T$ map $\mathbb R^3$ onto $\mathbb R^4$? Justify.

**9. True or False (12 points, 2 each).** State whether each statement is true or false, and justify: cite a theorem or definition if true, give a counterexample if false.

(a) If an augmented matrix has a pivot in every row, then the system it represents is consistent.

(b) If $A$ is a $3\times3$ matrix and $A\mathbf x=\mathbf 0$ has only the trivial solution, then the columns of $A$ span $\mathbb R^3$.

(c) If $A$ is a $4\times3$ matrix, then $A\mathbf x=\mathbf b$ has a solution for every $\mathbf b$ in $\mathbb R^4$.

(d) The solution set of $A\mathbf x=\mathbf b$ is always a translate of the solution set of $A\mathbf x=\mathbf 0$.

(e) If $T$ is linear and $T(\mathbf u)=T(\mathbf v)$ for some $\mathbf u\neq\mathbf v$, then $T$ is not one-to-one.

(f) Any set of vectors in $\mathbb R^n$ that contains the zero vector is linearly dependent.

**10. Proofs (8 points).**

(a) (4 pts) Let $A$ be an $m\times n$ matrix. Prove that if $\mathbf p$ and $\mathbf q$ are both solutions of $A\mathbf x=\mathbf b$, then $\mathbf p-\mathbf q$ is a solution of $A\mathbf x=\mathbf 0$.

(b) (4 pts) Let $T:\mathbb R^n\to\mathbb R^m$ be a **one-to-one** linear transformation. Prove that if $\{\mathbf v_1,\mathbf v_2,\mathbf v_3\}$ is linearly independent, then $\{T(\mathbf v_1),T(\mathbf v_2),T(\mathbf v_3)\}$ is linearly independent.

### Extra Credit (5 points ••)

Let $A$ be an $m\times n$ matrix. Prove that if $A\mathbf x=\mathbf b$ has exactly one solution for some $\mathbf b$, then $A\mathbf x=\mathbf c$ has at most one solution for **every** $\mathbf c$ in $\mathbb R^m$.

<!-- SOLUTIONS -->

## Answer Key — Practice Test 1

**1.** (a) Augmented matrix and row reduction ($R_2-3R_1$, $R_3+2R_1$, then $R_3-R_2$, then $R_1-2R_2$):

$$\begin{bmatrix}1&-3&2&-1&2\\3&-9&7&-1&8\\-2&6&-3&4&-2\end{bmatrix}\sim\begin{bmatrix}1&-3&2&-1&2\\0&0&1&2&2\\0&0&1&2&2\end{bmatrix}\sim\begin{bmatrix}1&-3&0&-5&-2\\0&0&1&2&2\\0&0&0&0&0\end{bmatrix}$$

(b) Pivot columns 1 and 3. Basic variables $x_1,x_3$; free variables $x_2,x_4$.

(c) $x_1=-2+3x_2+5x_4$, $\;x_2$ free, $\;x_3=2-2x_4$, $\;x_4$ free.

**2.** Row reduce ($R_2-3R_1$, $R_3-2R_1$, then $R_3-3R_2$):

$$\begin{bmatrix}1&-1&2&3\\3&-2&5&7\\2&1&h&k\end{bmatrix}\sim\begin{bmatrix}1&-1&2&3\\0&1&-1&-2\\0&3&h-4&k-6\end{bmatrix}\sim\begin{bmatrix}1&-1&2&3\\0&1&-1&-2\\0&0&h-1&k\end{bmatrix}$$

(a) Unique solution iff there is a pivot in every coefficient column: $h\neq1$ ($k$ arbitrary).

(b) No solution iff the last row is $[\,0\ 0\ 0\ \ c\,]$ with $c\ne0$: $h=1$ and $k\neq0$.

(c) Infinitely many iff the last row is all zeros: $h=1$ and $k=0$ ($x_3$ is then free).

**3.** (a) Row reduce $[\,A\ \ \mathbf b\,]$ ($R_2+2R_1$, $R_3-3R_1$, then $R_3+2R_2$):

$$\begin{bmatrix}1&3&-1&b_1\\-2&-5&4&b_2\\3&7&-7&b_3\end{bmatrix}\sim\begin{bmatrix}1&3&-1&b_1\\0&1&2&b_2+2b_1\\0&0&0&b_1+2b_2+b_3\end{bmatrix}$$

$\mathbf b$ is in the span iff the system is consistent, i.e. iff $b_1+2b_2+b_3=0$.

(b) $2+2(-3)+4=0$, so yes. The reduced form is $x_1=-1+7x_3$, $x_2=1-2x_3$; taking $x_3=0$: $\mathbf b=-\mathbf a_1+\mathbf a_2+0\,\mathbf a_3$. Check: $-(1,-2,3)+(3,-5,7)=(2,-3,4)$. (Any $x_3$ gives a valid combination.)

(c) No. The echelon form has no pivot in row 3, so by Theorem 4, $A\mathbf x=\mathbf b$ is not consistent for every $\mathbf b$; e.g. $\mathbf b=(0,0,1)$ fails the condition in (a).

**4.** (a) Row reduce ($R_2-3R_1$, $R_3+2R_1$, then $R_3-R_2$, then $R_1-R_2$): $[\,A\ \ \mathbf 0\,]\sim\begin{bmatrix}1&-2&0&-1&0\\0&0&1&3&0\\0&0&0&0&0\end{bmatrix}$, so $x_1=2x_2+x_4$, $x_3=-3x_4$, with $x_2,x_4$ free:

$$\mathbf x=x_2\begin{bmatrix}2\\1\\0\\0\end{bmatrix}+x_4\begin{bmatrix}1\\0\\-3\\1\end{bmatrix}.$$

(b) The same operations give $[\,A\ \ \mathbf b\,]\sim\begin{bmatrix}1&-2&0&-1&-1\\0&0&1&3&2\\0&0&0&0&0\end{bmatrix}$, so $x_1=-1+2x_2+x_4$, $x_3=2-3x_4$:

$$\mathbf x=\begin{bmatrix}-1\\0\\2\\0\end{bmatrix}+x_2\begin{bmatrix}2\\1\\0\\0\end{bmatrix}+x_4\begin{bmatrix}1\\0\\-3\\1\end{bmatrix}.$$

(c) The solution set of $A\mathbf x=\mathbf 0$ is the plane through the origin spanned by $(2,1,0,0)$ and $(1,0,-3,1)$ in $\mathbb R^4$. The solution set of $A\mathbf x=\mathbf b$ is the parallel plane through $\mathbf p=(-1,0,2,0)$: the homogeneous solution set translated by the particular solution $\mathbf p$ (Theorem 6).

**5.** (a) Row reduce $[\,\mathbf v_1\ \mathbf v_2\ \mathbf v_3\,]$ ($R_2-2R_1$, $R_3+R_1$, then $R_3-R_2$):

$$\begin{bmatrix}1&3&-1\\2&7&h\\-1&-2&4\end{bmatrix}\sim\begin{bmatrix}1&3&-1\\0&1&h+2\\0&1&3\end{bmatrix}\sim\begin{bmatrix}1&3&-1\\0&1&h+2\\0&0&1-h\end{bmatrix}$$

The set is dependent iff there is a free variable, iff $1-h=0$: $h=1$.

(b) With $h=1$, the equation $x_1\mathbf v_1+x_2\mathbf v_2+x_3\mathbf v_3=\mathbf 0$ gives $x_2=-3x_3$ and $x_1=-3x_2+x_3=10x_3$. Take $x_3=1$:

$$10\mathbf v_1-3\mathbf v_2+\mathbf v_3=\mathbf 0.$$

Check: $10(1,2,-1)-3(3,7,-2)+(-1,1,4)=(0,0,0)$.

**6.** Vectors (C, H, O): $\mathrm{C_2H_6}=(2,6,0)$, $\mathrm{O_2}=(0,0,2)$, $\mathrm{CO_2}=(1,0,2)$, $\mathrm{H_2O}=(0,2,1)$. The equation $x_1(2,6,0)+x_2(0,0,2)=x_3(1,0,2)+x_4(0,2,1)$ gives the homogeneous system

$$\begin{bmatrix}2&0&-1&0&0\\6&0&0&-2&0\\0&2&-2&-1&0\end{bmatrix}\sim\begin{bmatrix}1&0&0&-\tfrac13&0\\0&1&0&-\tfrac76&0\\0&0&1&-\tfrac23&0\end{bmatrix}$$

so $x_1=\tfrac13x_4$, $x_2=\tfrac76x_4$, $x_3=\tfrac23x_4$. Taking $x_4=6$:

$$2\,\mathrm{C_2H_6}+7\,\mathrm{O_2}\to4\,\mathrm{CO_2}+6\,\mathrm{H_2O}.$$

**7.** (a) Track the basis vectors: clockwise rotation by $\pi/2$ sends $\mathbf e_1\mapsto-\mathbf e_2$, $\mathbf e_2\mapsto\mathbf e_1$; reflection through $x_2=x_1$ swaps coordinates, sending $-\mathbf e_2\mapsto-\mathbf e_1$ and $\mathbf e_1\mapsto\mathbf e_2$. So $T(\mathbf e_1)=-\mathbf e_1$, $T(\mathbf e_2)=\mathbf e_2$:

$$A=\begin{bmatrix}-1&0\\0&1\end{bmatrix}.$$

(b) $A(x_1,x_2)=(-x_1,x_2)$: reflection through the $x_2$-axis.

(c) $S(\mathbf e_2)=S\!\left(\begin{bmatrix}0\\1\end{bmatrix}\right)=(1,-1,2)$. Since $\mathbf e_1=(1,2)-2(0,1)$, linearity gives $S(\mathbf e_1)=(3,0,5)-2(1,-1,2)=(1,2,1)$. So

$$[S]=\begin{bmatrix}1&1\\2&-1\\1&2\end{bmatrix}.$$

**8.** (a) $A=\begin{bmatrix}1&2&0\\-1&1&3\\2&1&-2\\0&3&4\end{bmatrix}$.

(b) Row reduce ($R_2+R_1$, $R_3-2R_1$; then $R_3+R_2$, $R_4-R_2$; then $R_4-R_3$):

$$A\sim\begin{bmatrix}1&2&0\\0&3&3\\0&-3&-2\\0&3&4\end{bmatrix}\sim\begin{bmatrix}1&2&0\\0&3&3\\0&0&1\\0&0&1\end{bmatrix}\sim\begin{bmatrix}1&2&0\\0&3&3\\0&0&1\\0&0&0\end{bmatrix}$$

Every column is a pivot column, so $A\mathbf x=\mathbf 0$ has only the trivial solution; the columns are linearly independent and, by Theorem 12, $T$ **is** one-to-one.

(c) No. Row 4 of the echelon form has no pivot, so the columns do not span $\mathbb R^4$ (Theorem 4) and $T$ is **not** onto (Theorem 12). (Even without row reducing: three vectors cannot span $\mathbb R^4$, since a $4\times3$ matrix has at most 3 pivots.)

**9.** (a) **False.** A pivot in the **augmented** column means inconsistency: $\begin{bmatrix}1&0&0\\0&0&1\end{bmatrix}$ has a pivot in every row, and its second row says $0=1$. (The correct statement is about a pivot in every row of the *coefficient* matrix.)

(b) **True.** Only the trivial solution means no free variables, so all 3 columns are pivot columns. Each pivot sits in a different row and there are only 3 rows, so every row has a pivot, and by Theorem 4 the columns span $\mathbb R^3$.

(c) **False.** A $4\times3$ matrix has at most 3 pivots, so it cannot have a pivot in all 4 rows; by Theorem 4 some $\mathbf b$ makes $A\mathbf x=\mathbf b$ inconsistent. (E.g. $A=\begin{bmatrix}1&0&0\\0&1&0\\0&0&1\\0&0&0\end{bmatrix}$, $\mathbf b=\mathbf e_4$.)

(d) **False.** If $A\mathbf x=\mathbf b$ is inconsistent its solution set is empty, which is not a translate of anything (the homogeneous solution set always contains $\mathbf 0$). Theorem 6 requires $A\mathbf x=\mathbf b$ to be consistent. Example: $A=\begin{bmatrix}0\end{bmatrix}$, $\mathbf b=\begin{bmatrix}1\end{bmatrix}$.

(e) **True.** One-to-one means each $\mathbf b$ is the image of **at most one** $\mathbf x$; here $T(\mathbf u)$ is the image of the two distinct vectors $\mathbf u$ and $\mathbf v$.

(f) **True.** If some $\mathbf v_j=\mathbf 0$, then $1\cdot\mathbf v_j$ plus $0$ times each other vector is $\mathbf 0$, a nontrivial dependence relation (Theorem 9).

**10.** (a) Given $A\mathbf p=\mathbf b$ and $A\mathbf q=\mathbf b$. By linearity of the matrix-vector product (Theorem 5),

$$A(\mathbf p-\mathbf q)=A\mathbf p-A\mathbf q=\mathbf b-\mathbf b=\mathbf 0.$$

(b) Suppose $c_1T(\mathbf v_1)+c_2T(\mathbf v_2)+c_3T(\mathbf v_3)=\mathbf 0$. By linearity, and since $T(\mathbf 0)=\mathbf 0$,

$$T(c_1\mathbf v_1+c_2\mathbf v_2+c_3\mathbf v_3)=\mathbf 0=T(\mathbf 0).$$

$T$ is one-to-one, so $c_1\mathbf v_1+c_2\mathbf v_2+c_3\mathbf v_3=\mathbf 0$. Since $\{\mathbf v_1,\mathbf v_2,\mathbf v_3\}$ is linearly independent, $c_1=c_2=c_3=0$. So the only dependence relation among the $T(\mathbf v_i)$ is the trivial one, and they are linearly independent.

### Extra Credit

Let $\mathbf p$ be the unique solution of $A\mathbf x=\mathbf b$.

*Step 1: $A\mathbf x=\mathbf 0$ has only the trivial solution.* If $A\mathbf w=\mathbf 0$, then $A(\mathbf p+\mathbf w)=A\mathbf p+A\mathbf w=\mathbf b$, so $\mathbf p+\mathbf w$ is also a solution of $A\mathbf x=\mathbf b$. By uniqueness, $\mathbf p+\mathbf w=\mathbf p$, so $\mathbf w=\mathbf 0$.

*Step 2: at most one solution for any $\mathbf c$.* Suppose $A\mathbf u=\mathbf c$ and $A\mathbf v=\mathbf c$. Then $A(\mathbf u-\mathbf v)=\mathbf c-\mathbf c=\mathbf 0$, so by Step 1, $\mathbf u-\mathbf v=\mathbf 0$, i.e. $\mathbf u=\mathbf v$.

Hence $A\mathbf x=\mathbf c$ has at most one solution for every $\mathbf c$ in $\mathbb R^m$. (It may have none: uniqueness for one $\mathbf b$ says nothing about existence for other $\mathbf c$.) $\blacksquare$
