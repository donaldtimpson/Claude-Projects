## Practice Test 2 — Matrix Algebra and Determinants (Chapters 2–3)

*Practice for Test 2 · 100 points core + 5 points extra credit · time 90 minutes. No calculator. Show all reasoning; partial credit is given. Justify every "yes/no" answer with a theorem, a computation, or a counterexample. Part I covers Chapters 2–3; Part II is cumulative.*

---

### Part I — Chapters 2–3 (80 points)

**1. Matrix Operations and Partitioned Matrices (6 points).** Let $A=\begin{bmatrix}2&-1&3\\1&0&-2\end{bmatrix}$ and $B=\begin{bmatrix}1&4\\0&-1\\2&1\end{bmatrix}$.

(a) (3 pts) Compute $AB$.

(b) (3 pts) Let $X$ be a $p\times q$ matrix, and let $M=\begin{bmatrix}I_p&X\\0&I_q\end{bmatrix}$. Use block multiplication to find $M^{-1}$, and verify your answer.

**2. The Inverse of a Matrix (10 points).** Let $A=\begin{bmatrix}1&-1&1\\-2&3&-1\\1&0&3\end{bmatrix}$.

(a) (7 pts) Find $A^{-1}$ by row reducing $[\,A\ \ I\,]$.

(b) (3 pts) Use $A^{-1}$ to solve $A\mathbf x=\mathbf b$ for $\mathbf b=\begin{bmatrix}2\\-1\\1\end{bmatrix}$.

**3. Invertible Linear Transformations (6 points).** Let $T:\mathbb R^2\to\mathbb R^2$ be defined by $T(x_1,x_2)=(4x_1+7x_2,\;x_1+2x_2)$.

(a) (2 pts) Find the standard matrix of $T$ and explain why $T$ is invertible.

(b) (4 pts) Find a formula for $T^{-1}(x_1,x_2)$.

**4. LU Factorization (8 points).** Let $A=\begin{bmatrix}1&-2&3\\3&-4&8\\-1&6&-8\end{bmatrix}$ and $\mathbf b=\begin{bmatrix}-3\\-6\\12\end{bmatrix}$.

(a) (5 pts) Find an LU factorization of $A$, with $L$ unit lower triangular.

(b) (3 pts) Use the factorization to solve $A\mathbf x=\mathbf b$: first solve $L\mathbf y=\mathbf b$, then $U\mathbf x=\mathbf y$.

**5. The Leontief Model (6 points).** An economy has two sectors, Manufacturing and Agriculture. Producing one unit of manufacturing output consumes $0.1$ unit of manufacturing and $0.3$ unit of agriculture. Producing one unit of agricultural output consumes $0.4$ unit of manufacturing and $0.2$ unit of agriculture.

(a) (2 pts) Write the consumption matrix $C$.

(b) (4 pts) Find the production vector $\mathbf x$ that satisfies a final demand of $45$ units of manufacturing and $15$ units of agriculture.

**6. Computer Graphics (6 points).**

(a) (4 pts) Find the $3\times3$ matrix that, acting on homogeneous coordinates, rotates points of $\mathbb R^2$ through $90^\circ$ **clockwise about the point $(1,3)$**.

(b) (2 pts) Use your matrix to find the image of the point $(2,5)$.

**7. Subspaces, Dimension, and Rank (12 points).** The matrix $A$ is row equivalent to the echelon form $B$:

$$A=\begin{bmatrix}1&0&-2&0&3\\2&1&-3&0&5\\-1&3&5&1&-4\\0&1&1&-2&-5\end{bmatrix}\sim B=\begin{bmatrix}1&2&0&0&1\\0&1&1&1&1\\0&0&0&1&2\\0&0&0&0&0\end{bmatrix}$$

(a) (4 pts) Find a basis for $\operatorname{Col}A$.

(b) (4 pts) Find a basis for $\operatorname{Nul}A$.

(c) (2 pts) Find $\operatorname{rank}A$ and $\dim\operatorname{Nul}A$, and show that they agree with the Rank Theorem.

(d) (2 pts) Is $\operatorname{Col}A=\mathbb R^4$? Is $\operatorname{Nul}A$ a subspace of $\mathbb R^4$ or of $\mathbb R^5$? Justify.

**8. Determinants (10 points).**

(a) (4 pts) Compute $\det\begin{bmatrix}2&0&1&0\\3&-1&4&2\\1&0&5&0\\6&3&-2&0\end{bmatrix}$ by cofactor expansion. Choose the row or column that makes the work shortest.

(b) (3 pts) Compute $\det\begin{bmatrix}1&-1&2\\3&-1&4\\-2&6&1\end{bmatrix}$ by row reducing to echelon form.

(c) (3 pts) Let $A$ and $B$ be $4\times4$ matrices with $\det A=3$ and $\det B=-1$. Find $\det(2A)$, $\det(A^TB^{-1})$, and $\det(B^5)$.

**9. Cramer's Rule and Area (8 points).**

(a) (4 pts) Find the values of $s$ for which the system below has a unique solution, and use Cramer's rule to find that solution.

$$\begin{aligned} s\,x_1 + 3x_2 &= 5 \\ 3x_1 + s\,x_2 &= -1 \end{aligned}$$

(b) (4 pts) Find the area of the parallelogram with vertices $(1,-1)$, $(4,1)$, $(2,3)$, and $(5,5)$. Then find the area of its image under the linear transformation with standard matrix $\begin{bmatrix}1&-2\\3&1\end{bmatrix}$.

**10. Proofs (8 points).**

(a) (4 pts) Let $A$ be an invertible $n\times n$ matrix. Prove that $A^T$ is invertible and that $(A^T)^{-1}=(A^{-1})^T$.

(b) (4 pts) Let $A$ be an $n\times n$ matrix with $A^3=0$. Prove that $A$ is not invertible.

### Part II — Cumulative (20 points)

**11. Systems, Spans, and Transformations (10 points).** Let $A=\begin{bmatrix}1&3&-1&2\\-2&-6&3&-1\\1&3&1&8\end{bmatrix}$ and $\mathbf b=\begin{bmatrix}1\\1\\7\end{bmatrix}$.

(a) (5 pts) Write the solution set of $A\mathbf x=\mathbf b$ in parametric vector form.

(b) (3 pts) Let $T(\mathbf x)=A\mathbf x$. Is $T$ one-to-one? Does $T$ map $\mathbb R^4$ onto $\mathbb R^3$? Justify each answer.

(c) (2 pts) Find a linear dependence relation among the columns $\mathbf a_1,\dots,\mathbf a_4$ of $A$.

**12. True or False (10 points, 2 each).** State whether each statement is true or false, and justify: cite a theorem or definition if true, give a counterexample if false.

(a) If $A$ is an $n\times n$ matrix with $A^2=I$, then $A=I$ or $A=-I$.

(b) If $A$ is an $n\times n$ matrix and $A\mathbf x=\mathbf 0$ has a nontrivial solution, then the columns of $A$ span $\mathbb R^n$.

(c) If $A$ is an $n\times n$ matrix and $c$ is a scalar, then $\det(cA)=c\det A$.

(d) If $\{\mathbf v_1,\mathbf v_2\}$ is a linearly dependent set in $\mathbb R^n$, then one of the vectors is a scalar multiple of the other.

(e) If $A$ is a $4\times6$ matrix with $\operatorname{rank}A=4$, then $\mathbf x\mapsto A\mathbf x$ maps $\mathbb R^6$ onto $\mathbb R^4$.

### Extra Credit (5 points ••)

Let $n$ be odd. Prove that there is no $n\times n$ matrix $A$ (with real entries) such that $A^2=-I$.

<!-- SOLUTIONS -->

## Answer Key — Practice Test 2

**1.** (a) $AB=\begin{bmatrix}2&-1&3\\1&0&-2\end{bmatrix}\begin{bmatrix}1&4\\0&-1\\2&1\end{bmatrix}=\begin{bmatrix}2+0+6&8+1+3\\1+0-4&4+0-2\end{bmatrix}=\begin{bmatrix}8&12\\-3&2\end{bmatrix}$.

(b) $M^{-1}=\begin{bmatrix}I_p&-X\\0&I_q\end{bmatrix}$. Find it by seeking $N=\begin{bmatrix}P&Q\\R&S\end{bmatrix}$ with $MN=I$: block multiplication gives $R=0$, $S=I_q$, $P+XR=I_p$, and $Q+XS=0$. So $P=I_p$ and $Q=-X$. Verify:

$$\begin{bmatrix}I_p&X\\0&I_q\end{bmatrix}\begin{bmatrix}I_p&-X\\0&I_q\end{bmatrix}=\begin{bmatrix}I_p&-X+X\\0&I_q\end{bmatrix}=I,\qquad\begin{bmatrix}I_p&-X\\0&I_q\end{bmatrix}\begin{bmatrix}I_p&X\\0&I_q\end{bmatrix}=\begin{bmatrix}I_p&X-X\\0&I_q\end{bmatrix}=I.$$

**2.** (a) Row reduce $[\,A\ \ I\,]$ ($R_2+2R_1$, $R_3-R_1$; then $R_3-R_2$; then $R_1-R_3$, $R_2-R_3$; then $R_1+R_2$):

$$\left[\begin{array}{ccc|ccc}1&-1&1&1&0&0\\-2&3&-1&0&1&0\\1&0&3&0&0&1\end{array}\right]\sim\left[\begin{array}{ccc|ccc}1&-1&1&1&0&0\\0&1&1&2&1&0\\0&0&1&-3&-1&1\end{array}\right]\sim\left[\begin{array}{ccc|ccc}1&0&0&9&3&-2\\0&1&0&5&2&-1\\0&0&1&-3&-1&1\end{array}\right]$$

$$A^{-1}=\begin{bmatrix}9&3&-2\\5&2&-1\\-3&-1&1\end{bmatrix}.$$

(b) $\mathbf x=A^{-1}\mathbf b=\begin{bmatrix}9&3&-2\\5&2&-1\\-3&-1&1\end{bmatrix}\begin{bmatrix}2\\-1\\1\end{bmatrix}=\begin{bmatrix}13\\7\\-4\end{bmatrix}$. Check: $A(13,7,-4)=(13-7-4,\;-26+21+4,\;13+0-12)=(2,-1,1)$.

**3.** (a) $A=\begin{bmatrix}4&7\\1&2\end{bmatrix}$. Since $\det A=4(2)-7(1)=1\neq0$, $A$ is invertible, (Theorem 4 of §2.2), so $T$ is invertible (Theorem 9 of §2.3).

(b) $T^{-1}$ has standard matrix $A^{-1}=\dfrac11\begin{bmatrix}2&-7\\-1&4\end{bmatrix}$, so

$$T^{-1}(x_1,x_2)=(2x_1-7x_2,\;-x_1+4x_2).$$

Check: $T(2x_1-7x_2,\;-x_1+4x_2)=(8x_1-28x_2-7x_1+28x_2,\;2x_1-7x_2-2x_1+8x_2)=(x_1,x_2)$.

**4.** (a) Reduce $A$ to echelon form with row replacements only ($R_2-3R_1$, $R_3+R_1$; then $R_3-2R_2$):

$$\begin{bmatrix}1&-2&3\\3&-4&8\\-1&6&-8\end{bmatrix}\sim\begin{bmatrix}1&-2&3\\0&2&-1\\0&4&-5\end{bmatrix}\sim\begin{bmatrix}1&-2&3\\0&2&-1\\0&0&-3\end{bmatrix}=U.$$

The entries of $L$ below the diagonal are the multipliers, with signs reversed: dividing column 1 of $A$ by its pivot $1$ gives $(1,3,-1)$, and dividing $(2,4)$ by the pivot $2$ gives $(1,2)$.

$$L=\begin{bmatrix}1&0&0\\3&1&0\\-1&2&1\end{bmatrix},\qquad U=\begin{bmatrix}1&-2&3\\0&2&-1\\0&0&-3\end{bmatrix}.$$

(b) $L\mathbf y=\mathbf b$ by forward substitution: $y_1=-3$, $y_2=-6-3y_1=3$, $y_3=12+y_1-2y_2=12-3-6=3$. So $\mathbf y=(-3,3,3)$.

$U\mathbf x=\mathbf y$ by back substitution: $-3x_3=3\Rightarrow x_3=-1$; $2x_2-x_3=3\Rightarrow x_2=1$; $x_1-2x_2+3x_3=-3\Rightarrow x_1=-3+2+3=2$.

$$\mathbf x=\begin{bmatrix}2\\1\\-1\end{bmatrix}.\qquad\text{Check: }A\mathbf x=(2-2-3,\;6-4-8,\;-2+6+8)=(-3,-6,12).$$

**5.** (a) Column $j$ holds the inputs needed per unit of sector $j$'s output:

$$C=\begin{bmatrix}0.1&0.4\\0.3&0.2\end{bmatrix}.$$

(b) Solve $(I-C)\mathbf x=\mathbf d$. $I-C=\begin{bmatrix}0.9&-0.4\\-0.3&0.8\end{bmatrix}$ with $\det(I-C)=0.72-0.12=0.6$, so

$$\mathbf x=(I-C)^{-1}\mathbf d=\frac1{0.6}\begin{bmatrix}0.8&0.4\\0.3&0.9\end{bmatrix}\begin{bmatrix}45\\15\end{bmatrix}=\frac1{0.6}\begin{bmatrix}42\\27\end{bmatrix}=\begin{bmatrix}70\\45\end{bmatrix}.$$

Manufacturing must produce $70$ units and Agriculture $45$. Check: $\mathbf x-C\mathbf x=(70-7-18,\;45-21-9)=(45,15)$.

**6.** (a) A $90^\circ$ clockwise rotation sends $\mathbf e_1\mapsto-\mathbf e_2$ and $\mathbf e_2\mapsto\mathbf e_1$. Translate $(1,3)$ to the origin, rotate, and translate back. Matrices act right to left:

$$\begin{bmatrix}1&0&1\\0&1&3\\0&0&1\end{bmatrix}\begin{bmatrix}0&1&0\\-1&0&0\\0&0&1\end{bmatrix}\begin{bmatrix}1&0&-1\\0&1&-3\\0&0&1\end{bmatrix}=\begin{bmatrix}0&1&-2\\-1&0&4\\0&0&1\end{bmatrix}.$$

(b) $\begin{bmatrix}0&1&-2\\-1&0&4\\0&0&1\end{bmatrix}\begin{bmatrix}2\\5\\1\end{bmatrix}=\begin{bmatrix}3\\2\\1\end{bmatrix}$, so the image is $(3,2)$. Check: $(2,5)$ sits at $(1,2)$ relative to $(1,3)$; a quarter turn clockwise gives $(2,-1)$; adding back $(1,3)$ gives $(3,2)$.

**7.** (a) The pivots of $B$ are in columns 1, 2, and 4, so the pivot columns **of $A$** form a basis for $\operatorname{Col}A$:

$$\left\{\begin{bmatrix}1\\2\\-1\\0\end{bmatrix},\ \begin{bmatrix}0\\1\\3\\1\end{bmatrix},\ \begin{bmatrix}0\\0\\1\\-2\end{bmatrix}\right\}.$$

(The columns of $B$ do **not** span $\operatorname{Col}A$: every column of $B$ has last entry $0$, but the columns of $A$ do not.)

(b) Finish reducing $B$ to reduced echelon form ($R_2-R_3$; then $R_1-2R_2$):

$$B\sim\begin{bmatrix}1&0&-2&0&3\\0&1&1&0&-1\\0&0&0&1&2\\0&0&0&0&0\end{bmatrix}.$$

So $x_1=2x_3-3x_5$, $x_2=-x_3+x_5$, $x_4=-2x_5$, with $x_3,x_5$ free:

$$\mathbf x=x_3\begin{bmatrix}2\\-1\\1\\0\\0\end{bmatrix}+x_5\begin{bmatrix}-3\\1\\0\\-2\\1\end{bmatrix},\qquad\text{basis for }\operatorname{Nul}A:\ \left\{\begin{bmatrix}2\\-1\\1\\0\\0\end{bmatrix},\ \begin{bmatrix}-3\\1\\0\\-2\\1\end{bmatrix}\right\}.$$

(c) $\operatorname{rank}A=3$ (three pivot columns) and $\dim\operatorname{Nul}A=2$ (two free variables). Rank Theorem: $3+2=5$, the number of columns of $A$.

(d) No. $\operatorname{Col}A$ has dimension $3$, so it is a proper subspace of $\mathbb R^4$ (equivalently, $B$ has no pivot in row 4). $\operatorname{Nul}A$ is a subspace of $\mathbb R^5$, because the solutions of $A\mathbf x=\mathbf 0$ have $5$ entries, one for each column of $A$.

**8.** (a) Column 4 has a single nonzero entry, $a_{24}=2$. Expand down column 4:

$$\det=2\cdot(-1)^{2+4}\det\begin{bmatrix}2&0&1\\1&0&5\\6&3&-2\end{bmatrix}.$$

In the $3\times3$, column 2 has a single nonzero entry, $3$, in position $(3,2)$: $3\cdot(-1)^{3+2}\det\begin{bmatrix}2&1\\1&5\end{bmatrix}=-3(10-1)=-27$. So $\det=2(-27)=-54$.

(b) Row replacements do not change the determinant ($R_2-3R_1$, $R_3+2R_1$; then $R_3-2R_2$):

$$\begin{bmatrix}1&-1&2\\3&-1&4\\-2&6&1\end{bmatrix}\sim\begin{bmatrix}1&-1&2\\0&2&-2\\0&4&5\end{bmatrix}\sim\begin{bmatrix}1&-1&2\\0&2&-2\\0&0&9\end{bmatrix}.$$

The determinant of a triangular matrix is the product of its diagonal entries: $1(2)(9)=18$.

(c) $\det(2A)=2^4\det A=16(3)=48$.

$\det(A^TB^{-1})=\det(A^T)\det(B^{-1})=\det A\cdot\dfrac1{\det B}=\dfrac{3}{-1}=-3$.

$\det(B^5)=(\det B)^5=(-1)^5=-1$.

**9.** (a) $\det A=\det\begin{bmatrix}s&3\\3&s\end{bmatrix}=s^2-9=(s-3)(s+3)$. The system has a unique solution iff $\det A\neq0$, i.e. **$s\neq\pm3$**. For those $s$,

$$x_1=\frac{\det\begin{bmatrix}5&3\\-1&s\end{bmatrix}}{s^2-9}=\frac{5s+3}{s^2-9},\qquad x_2=\frac{\det\begin{bmatrix}s&5\\3&-1\end{bmatrix}}{s^2-9}=\frac{-s-15}{s^2-9}.$$

(b) From the vertex $(1,-1)$, the two adjacent vertices give the edge vectors $(4,1)-(1,-1)=(3,2)$ and $(2,3)-(1,-1)=(1,4)$. (Check: $(1,-1)+(3,2)+(1,4)=(5,5)$, the fourth vertex.)

$$\text{Area}=\left|\det\begin{bmatrix}3&1\\2&4\end{bmatrix}\right|=|12-2|=10.$$

The image has area $|\det T|\cdot10=|1+6|\cdot10=70$.

**10.** (a) Use $(XY)^T=Y^TX^T$:

$$A^T(A^{-1})^T=(A^{-1}A)^T=I^T=I,\qquad(A^{-1})^TA^T=(AA^{-1})^T=I^T=I.$$

So $(A^{-1})^T$ is an inverse of $A^T$. Hence $A^T$ is invertible, and since a matrix's inverse is unique, $(A^T)^{-1}=(A^{-1})^T$.

(b) Take determinants of both sides of $A^3=0$. By the multiplicative property, $\det(A^3)=(\det A)^3$, and $\det 0=0$. So $(\det A)^3=0$, which forces $\det A=0$. A square matrix is invertible if and only if its determinant is nonzero (Theorem 4 of §3.2), so $A$ is not invertible. $\blacksquare$

(Another proof: if $A$ were invertible, multiplying $A^3=0$ on the left by $(A^{-1})^2$ would give $A=0$, which is not invertible. Contradiction.)

**11.** (a) Row reduce $[\,A\ \ \mathbf b\,]$ ($R_2+2R_1$, $R_3-R_1$; then $R_3-2R_2$; then $R_1+R_2$):

$$\begin{bmatrix}1&3&-1&2&1\\-2&-6&3&-1&1\\1&3&1&8&7\end{bmatrix}\sim\begin{bmatrix}1&3&-1&2&1\\0&0&1&3&3\\0&0&2&6&6\end{bmatrix}\sim\begin{bmatrix}1&3&0&5&4\\0&0&1&3&3\\0&0&0&0&0\end{bmatrix}.$$

So $x_1=4-3x_2-5x_4$, $x_3=3-3x_4$, with $x_2,x_4$ free:

$$\mathbf x=\begin{bmatrix}4\\0\\3\\0\end{bmatrix}+x_2\begin{bmatrix}-3\\1\\0\\0\end{bmatrix}+x_4\begin{bmatrix}-5\\0\\-3\\1\end{bmatrix}.$$

(b) **Not one-to-one.** $A\mathbf x=\mathbf 0$ has free variables, so it has nontrivial solutions (Theorem 11 of §1.9). Equivalently, four vectors in $\mathbb R^3$ are dependent. **Not onto.** The echelon form has no pivot in row 3, so the columns of $A$ do not span $\mathbb R^3$ (Theorem 4 of §1.4, Theorem 12 of §1.9).

(c) Column 2 is $3$ times column 1, so $3\mathbf a_1-\mathbf a_2=\mathbf 0$. Any nontrivial solution of $A\mathbf x=\mathbf 0$ also works, for example $x_2=1$, $x_4=0$, which gives $(-3,1,0,0)$. (Another: $x_4=1$ gives $-5\mathbf a_1-3\mathbf a_3+\mathbf a_4=\mathbf 0$.)

**12.** (a) **False.** $A=\begin{bmatrix}0&1\\1&0\end{bmatrix}$ swaps the coordinates, so $A^2=I$, but $A\neq\pm I$.

(b) **False.** By the Invertible Matrix Theorem, a nontrivial solution of $A\mathbf x=\mathbf 0$ means $A$ is **not** invertible, so its columns do **not** span $\mathbb R^n$. Example: $A=\begin{bmatrix}1&0\\0&0\end{bmatrix}$ has the nontrivial solution $(0,1)$, and its columns span only the $x_1$-axis.

(c) **False.** Multiplying each of the $n$ rows by $c$ multiplies the determinant by $c$ each time, so $\det(cA)=c^n\det A$. Example: $\det(2I_2)=4$, but $2\det I_2=2$.

(d) **True.** By Theorem 7 of §1.7, some vector is a linear combination of the others, and with only two vectors this means one is a multiple of the other. Directly: if $c_1\mathbf v_1+c_2\mathbf v_2=\mathbf 0$ with, say, $c_1\neq0$, then $\mathbf v_1=-\tfrac{c_2}{c_1}\mathbf v_2$.

(e) **True.** $\operatorname{rank}A=4$ means $A$ has 4 pivots, one in each of its 4 rows, so the columns of $A$ span $\mathbb R^4$ (Theorem 4 of §1.4) and the map is onto (Theorem 12 of §1.9). (Equivalently, $\operatorname{Col}A$ is a $4$-dimensional subspace of $\mathbb R^4$, so it is all of $\mathbb R^4$ by the Basis Theorem.)

### Extra Credit

Suppose $A^2=-I$. Take determinants of both sides. By the multiplicative property, $\det(A^2)=(\det A)^2$. And $-I$ is $I$ with each of its $n$ rows multiplied by $-1$, so $\det(-I)=(-1)^n=-1$, because $n$ is odd. Thus

$$(\det A)^2=-1.$$

But $\det A$ is a real number, and the square of a real number is never negative. This is a contradiction, so no such $A$ exists. $\blacksquare$

(The hypothesis that $n$ is odd is needed: $A=\begin{bmatrix}0&-1\\1&0\end{bmatrix}$, the $90^\circ$ rotation, satisfies $A^2=-I_2$.)
