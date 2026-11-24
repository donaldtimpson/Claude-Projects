## Test 2 — Matrix Algebra and Determinants (Chapters 2–3)

*Unit test · 100 points core + 5 points extra credit · time 90 minutes. No calculator. Show all reasoning; partial credit is given. Justify every "yes/no" answer with a theorem, a computation, or a counterexample. Part I covers Chapters 2–3; Part II is cumulative.*

---

### Part I — Chapters 2–3 (80 points)

**1. Matrix Operations and Partitioned Matrices (6 points).** Let $A=\begin{bmatrix}1&2&-1\\0&3&1\end{bmatrix}$ and $B=\begin{bmatrix}2&1\\-1&0\\3&4\end{bmatrix}$.

(a) (3 pts) Compute $AB$.

[work]: # "2.0in"

(b) (3 pts) Let $X$ be a $q\times p$ matrix, and let $M=\begin{bmatrix}I_p&0\\X&I_q\end{bmatrix}$. Use block multiplication to find $M^{-1}$, and verify your answer.

[work]: # "2.5in"

**2. The Inverse of a Matrix (10 points).** Let $A=\begin{bmatrix}1&2&1\\2&5&3\\-1&-1&1\end{bmatrix}$.

(a) (7 pts) Find $A^{-1}$ by row reducing $[\,A\ \ I\,]$.

[work]: # "4.0in"

(b) (3 pts) Use $A^{-1}$ to solve $A\mathbf x=\mathbf b$ for $\mathbf b=\begin{bmatrix}1\\0\\2\end{bmatrix}$.

[work]: # "1.5in"

**3. Invertible Linear Transformations (6 points).** Let $T:\mathbb R^2\to\mathbb R^2$ be defined by $T(x_1,x_2)=(3x_1-5x_2,\;-x_1+2x_2)$.

(a) (2 pts) Find the standard matrix of $T$ and explain why $T$ is invertible.

[work]: # "1.5in"

(b) (4 pts) Find a formula for $T^{-1}(x_1,x_2)$.

[work]: # "2.0in"

**4. LU Factorization (8 points).** Let $A=\begin{bmatrix}2&4&-1\\-4&-5&3\\2&-5&-2\end{bmatrix}$ and $\mathbf b=\begin{bmatrix}-4\\7\\3\end{bmatrix}$.

(a) (5 pts) Find an LU factorization of $A$, with $L$ unit lower triangular.

[work]: # "3.0in"

(b) (3 pts) Use the factorization to solve $A\mathbf x=\mathbf b$: first solve $L\mathbf y=\mathbf b$, then $U\mathbf x=\mathbf y$.

[work]: # "2.5in"

**5. The Leontief Model (6 points).** An economy has two sectors, Manufacturing and Agriculture. Producing one unit of manufacturing output consumes $0.2$ unit of manufacturing and $0.4$ unit of agriculture. Producing one unit of agricultural output consumes $0.3$ unit of manufacturing and $0.1$ unit of agriculture.

(a) (2 pts) Write the consumption matrix $C$.

[work]: # "1.0in"

(b) (4 pts) Find the production vector $\mathbf x$ that satisfies a final demand of $30$ units of manufacturing and $60$ units of agriculture.

[work]: # "2.5in"

**6. Computer Graphics (6 points).**

(a) (4 pts) Find the $3\times3$ matrix that, acting on homogeneous coordinates, rotates points of $\mathbb R^2$ through $90^\circ$ **counterclockwise about the point $(2,1)$**.

[work]: # "3.0in"

(b) (2 pts) Use your matrix to find the image of the point $(4,3)$.

[work]: # "1.0in"

**7. Subspaces, Dimension, and Rank (12 points).** The matrix $A$ is row equivalent to the echelon form $B$:

$$A=\begin{bmatrix}1&2&0&-1&0\\-2&-4&1&5&0\\3&6&-1&-6&1\\1&2&2&5&-1\end{bmatrix}\sim B=\begin{bmatrix}1&2&-1&-4&1\\0&0&1&3&-2\\0&0&0&0&3\\0&0&0&0&0\end{bmatrix}$$

(a) (4 pts) Find a basis for $\operatorname{Col}A$.

[work]: # "1.0in"

(b) (4 pts) Find a basis for $\operatorname{Nul}A$.

[work]: # "2.1in"

(c) (2 pts) Find $\operatorname{rank}A$ and $\dim\operatorname{Nul}A$, and show that they agree with the Rank Theorem.

[work]: # "0.6in"

(d) (2 pts) Is $\operatorname{Col}A=\mathbb R^4$? Is $\operatorname{Nul}A$ a subspace of $\mathbb R^4$ or of $\mathbb R^5$? Justify.

[work]: # "0.9in"

**8. Determinants (10 points).**

(a) (4 pts) Compute $\det\begin{bmatrix}3&0&0&5\\2&1&0&-1\\4&-2&0&7\\1&3&2&0\end{bmatrix}$ by cofactor expansion. Choose the row or column that makes the work shortest.

[work]: # "2.2in"

(b) (3 pts) Compute $\det\begin{bmatrix}1&3&-2\\2&5&-1\\-3&-7&6\end{bmatrix}$ by row reducing to echelon form.

[work]: # "1.8in"

(c) (3 pts) Let $A$ and $B$ be $3\times3$ matrices with $\det A=-2$ and $\det B=3$. Find $\det(2A)$, $\det(A^{-1}B^T)$, and $\det(A^3)$.

[work]: # "1.3in"

**9. Cramer's Rule and Area (8 points).**

(a) (4 pts) Find the values of $s$ for which the system below has a unique solution, and use Cramer's rule to find that solution.

$$\begin{aligned} 3s\,x_1 - 2x_2 &= 4 \\ -6x_1 + s\,x_2 &= 1 \end{aligned}$$

[work]: # "3.0in"

(b) (4 pts) Find the area of the parallelogram with vertices $(-2,1)$, $(-1,6)$, $(-1,-3)$, and $(0,2)$. Then find the area of its image under the linear transformation with standard matrix $\begin{bmatrix}2&1\\-1&3\end{bmatrix}$.

[work]: # "2.5in"

**10. Proofs (8 points).**

(a) (4 pts) Let $A$ and $B$ be invertible $n\times n$ matrices. Prove that $AB$ is invertible and that $(AB)^{-1}=B^{-1}A^{-1}$.

[work]: # "2.5in"

(b) (4 pts) Let $A$ be an $n\times n$ matrix with $A^TA=I$. Prove that $\det A=1$ or $\det A=-1$.

[work]: # "2.5in"

### Part II — Cumulative (20 points)

**11. Systems, Spans, and Transformations (10 points).** Let $A=\begin{bmatrix}1&-2&1&3\\2&-4&3&8\\-1&2&1&1\end{bmatrix}$ and $\mathbf b=\begin{bmatrix}2\\7\\4\end{bmatrix}$.

(a) (5 pts) Write the solution set of $A\mathbf x=\mathbf b$ in parametric vector form.

[work]: # "3.0in"

(b) (3 pts) Let $T(\mathbf x)=A\mathbf x$. Is $T$ one-to-one? Does $T$ map $\mathbb R^4$ onto $\mathbb R^3$? Justify each answer.

[work]: # "1.8in"

(c) (2 pts) Find a linear dependence relation among the columns $\mathbf a_1,\dots,\mathbf a_4$ of $A$.

[work]: # "0.9in"

**12. True or False (10 points, 2 each).** State whether each statement is true or false, and justify: cite a theorem or definition if true, give a counterexample if false.

(a) If $A$ and $B$ are $n\times n$ matrices with $AB=0$, then $A=0$ or $B=0$.

[work]: # "1.0in"

(b) If the columns of a $4\times4$ matrix $A$ are linearly independent, then $A\mathbf x=\mathbf b$ has exactly one solution for every $\mathbf b$ in $\mathbb R^4$.

[work]: # "1.0in"

(c) If $A$ and $B$ are $n\times n$ matrices, then $\det(A+B)=\det A+\det B$.

[work]: # "1.0in"

(d) Any set of vectors in $\mathbb R^n$ that contains the zero vector is linearly dependent.

[work]: # "1.0in"

(e) If $A$ is a $3\times5$ matrix, then $\dim\operatorname{Nul}A\ge2$.

[work]: # "1.0in"

### Extra Credit (5 points ••)

Let $A$ be an $n\times n$ matrix with $A^T=-A$, where $n$ is odd. Prove that $A$ is not invertible.

[work]: # "3.5in"

<!-- SOLUTIONS -->

## Answer Key — Test 2

**1.** (a) $AB=\begin{bmatrix}1&2&-1\\0&3&1\end{bmatrix}\begin{bmatrix}2&1\\-1&0\\3&4\end{bmatrix}=\begin{bmatrix}2-2-3&1+0-4\\0-3+3&0+0+4\end{bmatrix}=\begin{bmatrix}-3&-3\\0&4\end{bmatrix}$.

(b) $M^{-1}=\begin{bmatrix}I_p&0\\-X&I_q\end{bmatrix}$. Find it by seeking $N=\begin{bmatrix}P&Q\\R&S\end{bmatrix}$ with $MN=I$: block multiplication gives $P=I_p$, $Q=0$, $XP+R=0$, and $XQ+S=I_q$. So $R=-X$ and $S=I_q$. Verify:

$$\begin{bmatrix}I_p&0\\X&I_q\end{bmatrix}\begin{bmatrix}I_p&0\\-X&I_q\end{bmatrix}=\begin{bmatrix}I_p&0\\X-X&I_q\end{bmatrix}=I,\qquad\begin{bmatrix}I_p&0\\-X&I_q\end{bmatrix}\begin{bmatrix}I_p&0\\X&I_q\end{bmatrix}=\begin{bmatrix}I_p&0\\-X+X&I_q\end{bmatrix}=I.$$

**2.** (a) Row reduce $[\,A\ \ I\,]$ ($R_2-2R_1$, $R_3+R_1$; then $R_3-R_2$; then $R_1-R_3$, $R_2-R_3$; then $R_1-2R_2$):

$$\left[\begin{array}{ccc|ccc}1&2&1&1&0&0\\2&5&3&0&1&0\\-1&-1&1&0&0&1\end{array}\right]\sim\left[\begin{array}{ccc|ccc}1&2&1&1&0&0\\0&1&1&-2&1&0\\0&0&1&3&-1&1\end{array}\right]\sim\left[\begin{array}{ccc|ccc}1&0&0&8&-3&1\\0&1&0&-5&2&-1\\0&0&1&3&-1&1\end{array}\right]$$

$$A^{-1}=\begin{bmatrix}8&-3&1\\-5&2&-1\\3&-1&1\end{bmatrix}.$$

(b) $\mathbf x=A^{-1}\mathbf b=\begin{bmatrix}8&-3&1\\-5&2&-1\\3&-1&1\end{bmatrix}\begin{bmatrix}1\\0\\2\end{bmatrix}=\begin{bmatrix}10\\-7\\5\end{bmatrix}$. Check: $A(10,-7,5)=(10-14+5,\;20-35+15,\;-10+7+5)=(1,0,2)$.

**3.** (a) $A=\begin{bmatrix}3&-5\\-1&2\end{bmatrix}$. Since $\det A=3(2)-(-5)(-1)=1\neq0$, $A$ is invertible, (Theorem 4 of §2.2), so $T$ is invertible (Theorem 9 of §2.3).

(b) $T^{-1}$ has standard matrix $A^{-1}=\dfrac1{1}\begin{bmatrix}2&5\\1&3\end{bmatrix}$, so

$$T^{-1}(x_1,x_2)=(2x_1+5x_2,\;x_1+3x_2).$$

Check: $T(2x_1+5x_2,\;x_1+3x_2)=(6x_1+15x_2-5x_1-15x_2,\;-2x_1-5x_2+2x_1+6x_2)=(x_1,x_2)$.

**4.** (a) Reduce $A$ to echelon form with row replacements only ($R_2+2R_1$, $R_3-R_1$; then $R_3+3R_2$):

$$\begin{bmatrix}2&4&-1\\-4&-5&3\\2&-5&-2\end{bmatrix}\sim\begin{bmatrix}2&4&-1\\0&3&1\\0&-9&-1\end{bmatrix}\sim\begin{bmatrix}2&4&-1\\0&3&1\\0&0&2\end{bmatrix}=U.$$

The entries of $L$ below the diagonal are the multipliers, with signs reversed: dividing column 1 of $A$ by its pivot $2$ gives $(1,-2,1)$, and dividing $(3,-9)$ by the pivot $3$ gives $(1,-3)$.

$$L=\begin{bmatrix}1&0&0\\-2&1&0\\1&-3&1\end{bmatrix},\qquad U=\begin{bmatrix}2&4&-1\\0&3&1\\0&0&2\end{bmatrix}.$$

(b) $L\mathbf y=\mathbf b$ by forward substitution: $y_1=-4$, $y_2=7+2y_1=-1$, $y_3=3-y_1+3y_2=3+4-3=4$. So $\mathbf y=(-4,-1,4)$.

$U\mathbf x=\mathbf y$ by back substitution: $2x_3=4\Rightarrow x_3=2$; $3x_2+x_3=-1\Rightarrow x_2=-1$; $2x_1+4x_2-x_3=-4\Rightarrow 2x_1=-4+4+2\Rightarrow x_1=1$.

$$\mathbf x=\begin{bmatrix}1\\-1\\2\end{bmatrix}.\qquad\text{Check: }A\mathbf x=(2-4-2,\;-4+5+6,\;2+5-4)=(-4,7,3).$$

**5.** (a) Column $j$ holds the inputs needed per unit of sector $j$'s output:

$$C=\begin{bmatrix}0.2&0.3\\0.4&0.1\end{bmatrix}.$$

(b) Solve $(I-C)\mathbf x=\mathbf d$. $I-C=\begin{bmatrix}0.8&-0.3\\-0.4&0.9\end{bmatrix}$ with $\det(I-C)=0.72-0.12=0.6$, so

$$\mathbf x=(I-C)^{-1}\mathbf d=\frac1{0.6}\begin{bmatrix}0.9&0.3\\0.4&0.8\end{bmatrix}\begin{bmatrix}30\\60\end{bmatrix}=\frac1{0.6}\begin{bmatrix}45\\60\end{bmatrix}=\begin{bmatrix}75\\100\end{bmatrix}.$$

Manufacturing must produce $75$ units and Agriculture $100$. Check: $\mathbf x-C\mathbf x=(75-15-30,\;100-30-10)=(30,60)$.

**6.** (a) Translate $(2,1)$ to the origin, rotate, and translate back. Matrices act right to left:

$$\begin{bmatrix}1&0&2\\0&1&1\\0&0&1\end{bmatrix}\begin{bmatrix}0&-1&0\\1&0&0\\0&0&1\end{bmatrix}\begin{bmatrix}1&0&-2\\0&1&-1\\0&0&1\end{bmatrix}=\begin{bmatrix}0&-1&3\\1&0&-1\\0&0&1\end{bmatrix}.$$

(b) $\begin{bmatrix}0&-1&3\\1&0&-1\\0&0&1\end{bmatrix}\begin{bmatrix}4\\3\\1\end{bmatrix}=\begin{bmatrix}0\\3\\1\end{bmatrix}$, so the image is $(0,3)$. Check: $(4,3)$ sits at $(2,2)$ relative to $(2,1)$; a quarter turn counterclockwise gives $(-2,2)$; adding back $(2,1)$ gives $(0,3)$.

**7.** (a) The pivots of $B$ are in columns 1, 3, and 5, so the pivot columns **of $A$** form a basis for $\operatorname{Col}A$:

$$\left\{\begin{bmatrix}1\\-2\\3\\1\end{bmatrix},\ \begin{bmatrix}0\\1\\-1\\2\end{bmatrix},\ \begin{bmatrix}0\\0\\1\\-1\end{bmatrix}\right\}.$$

(The columns of $B$ do **not** span $\operatorname{Col}A$: every column of $B$ has last entry $0$, but the columns of $A$ do not.)

(b) Finish reducing $B$ to reduced echelon form ($\tfrac13R_3$; $R_2+2R_3$, $R_1-R_3$; $R_1+R_2$):

$$B\sim\begin{bmatrix}1&2&0&-1&0\\0&0&1&3&0\\0&0&0&0&1\\0&0&0&0&0\end{bmatrix}.$$

So $x_1=-2x_2+x_4$, $x_3=-3x_4$, $x_5=0$, with $x_2,x_4$ free:

$$\mathbf x=x_2\begin{bmatrix}-2\\1\\0\\0\\0\end{bmatrix}+x_4\begin{bmatrix}1\\0\\-3\\1\\0\end{bmatrix},\qquad\text{basis for }\operatorname{Nul}A:\ \left\{\begin{bmatrix}-2\\1\\0\\0\\0\end{bmatrix},\ \begin{bmatrix}1\\0\\-3\\1\\0\end{bmatrix}\right\}.$$

(c) $\operatorname{rank}A=3$ (three pivot columns) and $\dim\operatorname{Nul}A=2$ (two free variables). Rank Theorem: $3+2=5$, the number of columns of $A$.

(d) No. $\operatorname{Col}A$ has dimension $3$, so it is a proper subspace of $\mathbb R^4$ (equivalently, $B$ has no pivot in row 4). $\operatorname{Nul}A$ is a subspace of $\mathbb R^5$, because the solutions of $A\mathbf x=\mathbf 0$ have $5$ entries, one for each column of $A$.

**8.** (a) Column 3 has a single nonzero entry, $a_{43}=2$. Expand down column 3:

$$\det=2\cdot(-1)^{4+3}\det\begin{bmatrix}3&0&5\\2&1&-1\\4&-2&7\end{bmatrix}=-2\det\begin{bmatrix}3&0&5\\2&1&-1\\4&-2&7\end{bmatrix}.$$

Expand the $3\times3$ along row 1: $3\big(1\cdot7-(-1)(-2)\big)-0+5\big(2(-2)-1\cdot4\big)=3(5)+5(-8)=-25$. So $\det=-2(-25)=50$.

(b) Row replacements do not change the determinant ($R_2-2R_1$, $R_3+3R_1$; then $R_3+2R_2$):

$$\begin{bmatrix}1&3&-2\\2&5&-1\\-3&-7&6\end{bmatrix}\sim\begin{bmatrix}1&3&-2\\0&-1&3\\0&2&0\end{bmatrix}\sim\begin{bmatrix}1&3&-2\\0&-1&3\\0&0&6\end{bmatrix}.$$

The determinant of a triangular matrix is the product of its diagonal entries: $1(-1)(6)=-6$.

(c) $\det(2A)=2^3\det A=8(-2)=-16$.

$\det(A^{-1}B^T)=\det(A^{-1})\det(B^T)=\dfrac{1}{\det A}\cdot\det B=\dfrac{3}{-2}=-\dfrac32$ (multiplicative property, and $\det B^T=\det B$).

$\det(A^3)=(\det A)^3=(-2)^3=-8$.

**9.** (a) $\det A=\det\begin{bmatrix}3s&-2\\-6&s\end{bmatrix}=3s^2-12=3(s-2)(s+2)$. The system has a unique solution iff $\det A\neq0$, i.e. **$s\neq\pm2$**. For those $s$,

$$x_1=\frac{\det\begin{bmatrix}4&-2\\1&s\end{bmatrix}}{3(s^2-4)}=\frac{2(2s+1)}{3(s^2-4)},\qquad x_2=\frac{\det\begin{bmatrix}3s&4\\-6&1\end{bmatrix}}{3(s^2-4)}=\frac{3s+24}{3(s^2-4)}=\frac{s+8}{s^2-4}.$$

(b) From the vertex $(-2,1)$, the two adjacent vertices give the edge vectors $(-1,6)-(-2,1)=(1,5)$ and $(-1,-3)-(-2,1)=(1,-4)$. (Check: $(-2,1)+(1,5)+(1,-4)=(0,2)$, the fourth vertex.)

$$\text{Area}=\left|\det\begin{bmatrix}1&1\\5&-4\end{bmatrix}\right|=|-4-5|=9.$$

The image has area $|\det T|\cdot9=|6+1|\cdot9=63$.

**10.** (a) Compute both products, using associativity:

$$(AB)(B^{-1}A^{-1})=A(BB^{-1})A^{-1}=AIA^{-1}=AA^{-1}=I,$$
$$(B^{-1}A^{-1})(AB)=B^{-1}(A^{-1}A)B=B^{-1}IB=B^{-1}B=I.$$

So $B^{-1}A^{-1}$ is an inverse of $AB$. Hence $AB$ is invertible, and since a matrix's inverse is unique, $(AB)^{-1}=B^{-1}A^{-1}$.

(b) Take determinants of both sides of $A^TA=I$. By the multiplicative property and $\det A^T=\det A$,

$$\det(A^TA)=\det(A^T)\det(A)=(\det A)^2,\qquad\det I=1.$$

So $(\det A)^2=1$, and therefore $\det A=1$ or $\det A=-1$. $\blacksquare$

**11.** (a) Row reduce $[\,A\ \ \mathbf b\,]$ ($R_2-2R_1$, $R_3+R_1$; then $R_3-2R_2$; then $R_1-R_2$):

$$\begin{bmatrix}1&-2&1&3&2\\2&-4&3&8&7\\-1&2&1&1&4\end{bmatrix}\sim\begin{bmatrix}1&-2&1&3&2\\0&0&1&2&3\\0&0&2&4&6\end{bmatrix}\sim\begin{bmatrix}1&-2&0&1&-1\\0&0&1&2&3\\0&0&0&0&0\end{bmatrix}.$$

So $x_1=-1+2x_2-x_4$, $x_3=3-2x_4$, with $x_2,x_4$ free:

$$\mathbf x=\begin{bmatrix}-1\\0\\3\\0\end{bmatrix}+x_2\begin{bmatrix}2\\1\\0\\0\end{bmatrix}+x_4\begin{bmatrix}-1\\0\\-2\\1\end{bmatrix}.$$

(b) **Not one-to-one.** $A\mathbf x=\mathbf 0$ has free variables, so it has nontrivial solutions (Theorem 11 of §1.9). Equivalently, four vectors in $\mathbb R^3$ are dependent. **Not onto.** The echelon form has no pivot in row 3, so the columns of $A$ do not span $\mathbb R^3$ (Theorem 4 of §1.4, Theorem 12 of §1.9).

(c) Column 2 is $-2$ times column 1, so $2\mathbf a_1+\mathbf a_2=\mathbf 0$. Any nontrivial solution of $A\mathbf x=\mathbf 0$ also works, for example $x_2=1$, $x_4=0$, which gives $(2,1,0,0)$. (Another: $x_4=1$ gives $-\mathbf a_1-2\mathbf a_3+\mathbf a_4=\mathbf 0$.)

**12.** (a) **False.** $A=B=\begin{bmatrix}0&1\\0&0\end{bmatrix}$ gives $AB=\begin{bmatrix}0&0\\0&0\end{bmatrix}$, although neither is the zero matrix.

(b) **True.** By the Invertible Matrix Theorem, linearly independent columns make the square matrix $A$ invertible, and then $A\mathbf x=\mathbf b$ has the unique solution $A^{-1}\mathbf b$ (Theorem 5 of §2.2).

(c) **False.** $A=B=I_2$: $\det(A+B)=\det(2I_2)=4$, but $\det A+\det B=2$.

(d) **True.** If $\mathbf v_1=\mathbf 0$, then $1\cdot\mathbf v_1+0\mathbf v_2+\cdots+0\mathbf v_p=\mathbf 0$ is a nontrivial dependence relation (Theorem 9 of §1.7).

(e) **True.** $\operatorname{rank}A\le3$, because there are at most three pivots, one per row. By the Rank Theorem, $\dim\operatorname{Nul}A=5-\operatorname{rank}A\ge2$.

### Extra Credit

Take determinants of both sides of $A^T=-A$. Since $\det A^T=\det A$, and $-A$ is $A$ with each of its $n$ rows multiplied by $-1$,

$$\det A=\det A^T=\det(-A)=(-1)^n\det A=-\det A,$$

because $n$ is odd. So $2\det A=0$, which gives $\det A=0$, and $A$ is not invertible (Theorem 4 of §3.2). $\blacksquare$

(The hypothesis that $n$ is odd is needed: $\begin{bmatrix}0&1\\-1&0\end{bmatrix}$ satisfies $A^T=-A$ and has determinant $1$.)
