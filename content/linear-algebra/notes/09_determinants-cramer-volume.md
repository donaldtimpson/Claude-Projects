# Linear Algebra — Lecture Notes

**Text:** Lay, *Linear Algebra and Its Applications*, 5th ed.
**Chapter 3 — Determinants**
**Sections covered:** 3.1 Introduction to Determinants (carried over from 08) · 3.2 Properties of Determinants · 3.3 Cramer's Rule, Volume, and Linear Transformations

> *Roadmap:* §3.1 defines the $n\times n$ determinant recursively by **cofactor expansion**, shows the expansion works along any row or column, and gets the determinant of a triangular matrix for free. That definition is far too slow to compute with, and §3.2 fixes it: the secret of determinants is how they change under **row operations**. Reducing to echelon form gives a fast method, proves the central fact **$A$ is invertible $\iff \det A \ne 0$**, and leads to $\det A^T = \det A$ and the **multiplicative property** $\det AB = (\det A)(\det B)$. §3.3 turns the theory into formulas and geometry: **Cramer's rule** for the solution of $A\mathbf x = \mathbf b$, the **adjugate formula** for $A^{-1}$, and the interpretation of $|\det A|$ as **area or volume**, which says exactly how much a linear transformation stretches area.

---

## §3.1 — Introduction to Determinants

**Chapter 3 overview.** §3.1 introduces the determinant. §3.2 derives an invertibility criterion for square matrices that is central in Chapter 5. §3.3 shows that the determinant measures how much a linear transformation changes the **area** of a figure. Applied locally, this is the **Jacobian** of multivariable calculus, which answers how much a map (such as a flat map of the globe) stretches area near the poles.

### Discovering the $3\times3$ Determinant

From §2.2: a $2\times2$ matrix is invertible if and only if its determinant $a_{11}a_{22} - a_{12}a_{21}$ is nonzero. To extend this to larger matrices, find the right quantity for a $3\times3$ matrix by row reducing an invertible $A = [a_{ij}]$ and watching what appears.

Assume $a_{11}\ne0$. Multiply rows 2 and 3 by $a_{11}$, then subtract multiples of row 1 to clear column 1:

$$
\begin{bmatrix} a_{11} & a_{12} & a_{13}\\ a_{11}a_{21} & a_{11}a_{22} & a_{11}a_{23}\\ a_{11}a_{31} & a_{11}a_{32} & a_{11}a_{33}\end{bmatrix}
\sim
\begin{bmatrix} a_{11} & a_{12} & a_{13}\\ 0 & a_{11}a_{22} - a_{12}a_{21} & a_{11}a_{23} - a_{13}a_{21}\\ 0 & a_{11}a_{32} - a_{12}a_{31} & a_{11}a_{33} - a_{13}a_{31}\end{bmatrix} \tag{1}
$$

Since $A$ is invertible, the $(2,2)$- or $(3,2)$-entry on the right is nonzero; say the $(2,2)$-entry (otherwise interchange rows 2 and 3 first). Multiply row 3 by $a_{11}a_{22} - a_{12}a_{21}$, then add $-(a_{11}a_{32} - a_{12}a_{31})$ times row 2 to it. This gives

$$
A \sim
\begin{bmatrix} a_{11} & a_{12} & a_{13}\\ 0 & a_{11}a_{22} - a_{12}a_{21} & a_{11}a_{23} - a_{13}a_{21}\\ 0 & 0 & a_{11}\Delta\end{bmatrix},
$$

where

$$\Delta = a_{11}a_{22}a_{33} + a_{12}a_{23}a_{31} + a_{13}a_{21}a_{32} - a_{11}a_{23}a_{32} - a_{12}a_{21}a_{33} - a_{13}a_{22}a_{31}. \tag{2}$$

Since $A$ is invertible, the last row must hold a pivot, so $\Delta \ne 0$. (The converse is also true; §3.2.) We call $\Delta$ in (2) the **determinant** of the $3\times3$ matrix $A$.

**Rewriting $\Delta$ with $2\times2$ determinants.** For a $1\times1$ matrix $A = [a_{11}]$, define $\det A = a_{11}$. Group the six terms of $\Delta$ by the first-row entry they contain:
$$\Delta = (a_{11}a_{22}a_{33} - a_{11}a_{23}a_{32}) - (a_{12}a_{21}a_{33} - a_{12}a_{23}a_{31}) + (a_{13}a_{21}a_{32} - a_{13}a_{22}a_{31}),$$
that is,
$$
\Delta = a_{11}\cdot\det\begin{bmatrix} a_{22} & a_{23}\\ a_{32} & a_{33}\end{bmatrix}
- a_{12}\cdot\det\begin{bmatrix} a_{21} & a_{23}\\ a_{31} & a_{33}\end{bmatrix}
+ a_{13}\cdot\det\begin{bmatrix} a_{21} & a_{22}\\ a_{31} & a_{32}\end{bmatrix}.
$$
For brevity,
$$\Delta = a_{11}\cdot\det A_{11} - a_{12}\cdot\det A_{12} + a_{13}\cdot\det A_{13}, \tag{3}$$
where $A_{11}, A_{12}, A_{13}$ are obtained from $A$ by deleting the first row and one of the three columns.

**Notation.** For any square matrix $A$, **$A_{ij}$ is the submatrix formed by deleting the $i$th row and $j$th column of $A$.** For example,

$$
A = \begin{bmatrix} 1 & -2 & 5 & 0\\ 2 & 0 & 4 & -1\\ 3 & 1 & 0 & 7\\ 0 & 4 & -2 & 0\end{bmatrix}
\quad\Longrightarrow\quad
A_{32} = \begin{bmatrix} 1 & 5 & 0\\ 2 & 4 & -1\\ 0 & -2 & 0\end{bmatrix}
\quad(\text{cross out row 3 and column 2}).
$$

### The Definition

Formula (3) suggests a **recursive** definition: a $3\times3$ determinant is built from $2\times2$ determinants, a $4\times4$ from $3\times3$ determinants, and in general an $n\times n$ determinant from $(n-1)\times(n-1)$ determinants.

> **📗 DEFINITION.** For $n \ge 2$, the **determinant** of an $n\times n$ matrix $A = [a_{ij}]$ is the sum of $n$ terms of the form $\pm a_{1j}\det A_{1j}$, with plus and minus signs alternating, where the entries $a_{11}, a_{12}, \dots, a_{1n}$ are from the first row of $A$. In symbols,
> $$\det A = a_{11}\det A_{11} - a_{12}\det A_{12} + \cdots + (-1)^{1+n}a_{1n}\det A_{1n} = \sum_{j=1}^{n}(-1)^{1+j}a_{1j}\det A_{1j}.$$

For $n = 2$ this gives $a_{11}a_{22} - a_{12}a_{21}$, agreeing with §2.2. For $n = 3$ it is formula (3).

#### Example 1 — a $3\times3$ determinant from the definition (worked)

$$
A = \begin{bmatrix} 1 & 5 & 0\\ 2 & 4 & -1\\ 0 & -2 & 0\end{bmatrix}.
$$

$$
\det A = 1\cdot\det\begin{bmatrix} 4 & -1\\ -2 & 0\end{bmatrix} - 5\cdot\det\begin{bmatrix} 2 & -1\\ 0 & 0\end{bmatrix} + 0\cdot\det\begin{bmatrix} 2 & 4\\ 0 & -2\end{bmatrix}
= 1(0-2) - 5(0-0) + 0(-4-0) = \boxed{-2}.
$$

**Vertical-bar notation.** A pair of vertical lines in place of brackets also denotes a determinant:
$$\det A = 1\begin{vmatrix} 4 & -1\\ -2 & 0\end{vmatrix} - 5\begin{vmatrix} 2 & -1\\ 0 & 0\end{vmatrix} + 0\begin{vmatrix} 2 & 4\\ 0 & -2\end{vmatrix} = \cdots = -2.$$

### Cofactors and Cofactor Expansion

> **📗 DEFINITION.** Given $A = [a_{ij}]$, the **$(i,j)$-cofactor** of $A$ is the number
> $$C_{ij} = (-1)^{i+j}\det A_{ij}. \tag{4}$$

With cofactors the definition reads
$$\det A = a_{11}C_{11} + a_{12}C_{12} + \cdots + a_{1n}C_{1n},$$
the **cofactor expansion across the first row** of $A$.

> **📐 THEOREM 1.** The determinant of an $n\times n$ matrix $A$ can be computed by a cofactor expansion across any row or down any column. The expansion across the $i$th row using the cofactors in (4) is
> $$\det A = a_{i1}C_{i1} + a_{i2}C_{i2} + \cdots + a_{in}C_{in}.$$
> The cofactor expansion down the $j$th column is
> $$\det A = a_{1j}C_{1j} + a_{2j}C_{2j} + \cdots + a_{nj}C_{nj}.$$

The proof takes four steps, by induction on $n$ from the definition; later steps use earlier ones. Steps 1 and 3 are checked directly for $n=2$; Step 2 starts from the trivial $1\times1$ case. Throughout, **$M$ denotes $A$ with two rows and two columns deleted**, specified in each step.

> **🔎 Proof.**
>
> **Step 1 — first column = first row.** *Claim: $\sum_i (-1)^{i+1}a_{i1}\det A_{i1} = \det A$.* For $n=2$: $a_{11}a_{22} - a_{21}a_{12} = \det A$ ✓. Let $n\ge3$ and assume the claim for size $n-1$. Both sides contain the term $a_{11}\det A_{11}$. The remaining terms are:
> - *Row side,* $j\ge2$: expand $\det A_{1j}$ down its first column (inductive hypothesis). That column is original column 1 without $a_{11}$, and original row $i\ge2$ sits in row $i-1$ of $A_{1j}$. So $\det A_{1j} = \sum_{i\ge2}(-1)^{(i-1)+1}a_{i1}\det M$, where $M$ deletes rows $1, i$ and columns $1, j$ from $A$. Term: $(-1)^{1+j}(-1)^{i}\,a_{1j}a_{i1}\det M = (-1)^{i+j+1}a_{1j}a_{i1}\det M$.
> - *Column side,* $i\ge2$: expand $\det A_{i1}$ across its first row (the definition). That row is original row 1 without $a_{11}$, and original column $j\ge2$ sits in column $j-1$. So $\det A_{i1} = \sum_{j\ge2}(-1)^{1+(j-1)}a_{1j}\det M$, with the **same** $M$. Term: $(-1)^{i+1}(-1)^{j}\,a_{i1}a_{1j}\det M = (-1)^{i+j+1}a_{1j}a_{i1}\det M$.
>
> Each pair $(i,j)$ with $i,j\ge2$ contributes the same term to both sides, so the sums are equal.
>
> **Step 2 — $\det A^T = \det A$.** For $n=1$ it is trivial. Assume it for size $n-1$. The first row of $A^T$ is the first column of $A$, and deleting row 1 and column $j$ of $A^T$ gives $(A_{j1})^T$. So, by the definition and then the inductive hypothesis,
> $$\det A^T = \sum_j (-1)^{1+j}a_{j1}\det (A_{j1})^T = \sum_j (-1)^{1+j}a_{j1}\det A_{j1},$$
> which is the first-column expansion of $A$, equal to $\det A$ by Step 1.
>
> **Step 3 — any row.** *Claim: for each $i$, $\sum_k(-1)^{i+k}a_{ik}\det A_{ik} = \det A$.* For $i=1$ this is the definition; for $n = 2$, $i = 2$: $-a_{21}a_{12} + a_{22}a_{11} = \det A$ ✓. Let $n\ge3$, $i\ge2$, and assume the claim for size $n-1$. For $j\ne k$ let $M$ delete rows $1, i$ and columns $j, k$.
> - *Definition (row 1):* $\det A = \sum_j(-1)^{1+j}a_{1j}\det A_{1j}$. In $A_{1j}$, original row $i$ is row $i-1$, and original column $k$ is column $k' = k$ if $k<j$, $k' = k-1$ if $k>j$. Expanding across that row (inductive hypothesis), $\det A_{1j} = \sum_{k\ne j}(-1)^{(i-1)+k'}a_{ik}\det M$. Sign of the $(j,k)$ term: $(-1)^{i+j+k'}$.
> - *Row $i$ expansion:* $\sum_k(-1)^{i+k}a_{ik}\det A_{ik}$. In $A_{ik}$, row 1 is still row 1, and original column $j$ is column $j' = j$ if $j<k$, $j' = j-1$ if $j>k$. By the definition, $\det A_{ik} = \sum_{j\ne k}(-1)^{1+j'}a_{1j}\det M$. Sign of the $(j,k)$ term: $(-1)^{i+k+1+j'}$.
>
> Compare exponents mod 2. If $j<k$: $i+j+(k-1)$ vs. $i+k+1+j$, which differ by $2$. If $j>k$: $i+j+k$ vs. $i+k+1+(j-1)$, which are equal. So every term $a_{1j}a_{ik}\det M$ carries the same sign in both expansions, and the expansion across row $i$ equals $\det A$.
>
> **Step 4 — any column.** Expand $A$ down column $j$ and compare it with the expansion of $A^T$ across row $j$. Entry $(j,i)$ of $A^T$ is $a_{ij}$, and deleting row $j$ and column $i$ of $A^T$ gives $(A_{ij})^T$, so
> $$\sum_i(-1)^{j+i}a_{ij}\det(A_{ij})^T = \sum_i(-1)^{i+j}a_{ij}\det A_{ij}$$
> by Step 2 applied to the $(n-1)\times(n-1)$ matrices $A_{ij}$. The left side equals $\det A^T$ by Step 3, and $\det A^T = \det A$ by Step 2. So the column-$j$ expansion equals $\det A$. $\blacksquare$

> **💡** Step 2, $\det A^T = \det A$, reappears in §3.2 as Theorem 5. It is the reason that every fact about **rows** of a determinant has a twin about **columns**.

**The checkerboard.** The sign in $C_{ij}$ depends on the **position** of $a_{ij}$, not on the sign of $a_{ij}$ itself. The factor $(-1)^{i+j}$ makes the pattern

$$
\begin{bmatrix} + & - & + & \cdots\\ - & + & - & \\ + & - & + & \\ \vdots & & & \ddots\end{bmatrix}
$$

> **⚠ Watch for:** the two separate signs. In $a_{ij}C_{ij} = (-1)^{i+j}a_{ij}\det A_{ij}$, the checkerboard sign $(-1)^{i+j}$ and the sign of the entry $a_{ij}$ are independent. In Example 2 below, $a_{32} = -2$ sits on a "$-$" square, and the two minus signs combine to $+2$.

#### Example 2 — expansion across the third row (worked)

Same matrix as Example 1:
$$
A = \begin{bmatrix} 1 & 5 & 0\\ 2 & 4 & -1\\ 0 & -2 & 0\end{bmatrix}.
$$

$$
\begin{aligned}
\det A &= a_{31}C_{31} + a_{32}C_{32} + a_{33}C_{33}\\
&= (-1)^{3+1}a_{31}\det A_{31} + (-1)^{3+2}a_{32}\det A_{32} + (-1)^{3+3}a_{33}\det A_{33}\\
&= 0\begin{vmatrix} 5 & 0\\ 4 & -1\end{vmatrix} - (-2)\begin{vmatrix} 1 & 0\\ 2 & -1\end{vmatrix} + 0\begin{vmatrix} 1 & 5\\ 2 & 4\end{vmatrix}\\
&= 0 + 2(-1) + 0 = \boxed{-2},
\end{aligned}
$$

matching Example 1, with only one $2\times2$ determinant to compute.

> **💡 Strategy:** expand along the row or column with the **most zeros**. Each zero entry kills its whole term, so its cofactor never has to be computed.

#### Example 3 — a $5\times5$ determinant by repeated column expansion (worked)

$$
A = \begin{bmatrix} 3 & -7 & 8 & 9 & -6\\ 0 & 2 & -5 & 7 & 3\\ 0 & 0 & 1 & 5 & 0\\ 0 & 0 & 2 & 4 & -1\\ 0 & 0 & 0 & -2 & 0\end{bmatrix}.
$$

Down the first column, every term but the first is zero:
$$
\det A = 3\cdot\begin{vmatrix} 2 & -5 & 7 & 3\\ 0 & 1 & 5 & 0\\ 0 & 2 & 4 & -1\\ 0 & 0 & -2 & 0\end{vmatrix} + 0\cdot C_{21} + 0\cdot C_{31} + 0\cdot C_{41} + 0\cdot C_{51}.
$$
From now on, omit the zero terms. Expand the $4\times4$ determinant down its first column:
$$
\det A = 3\cdot2\cdot\begin{vmatrix} 1 & 5 & 0\\ 2 & 4 & -1\\ 0 & -2 & 0\end{vmatrix}.
$$
This $3\times3$ determinant is Example 1's, $-2$. So $\det A = 3\cdot2\cdot(-2) = \boxed{-12}$.

### Triangular Matrices

Example 3's matrix was *nearly* triangular. The same method proves:

> **📐 THEOREM 2.** If $A$ is a triangular matrix, then $\det A$ is the product of the entries on the main diagonal of $A$.

> **🔎 Proof.** Induct on $n$. For $n = 1$, $\det[a_{11}] = a_{11}$. Let $n\ge2$ and assume the result for size $n-1$.
> - *Upper triangular.* Column 1 is $(a_{11}, 0, \dots, 0)$. Expanding down it (Theorem 1) leaves the single term $a_{11}C_{11} = a_{11}\det A_{11}$. Deleting row 1 and column 1 leaves $A_{11}$ upper triangular with diagonal $a_{22},\dots,a_{nn}$. By induction $\det A_{11} = a_{22}\cdots a_{nn}$, so $\det A = a_{11}a_{22}\cdots a_{nn}$.
> - *Lower triangular.* Row 1 is $(a_{11}, 0, \dots, 0)$. The definition (first-row expansion) leaves $a_{11}\det A_{11}$, with $A_{11}$ lower triangular with diagonal $a_{22},\dots,a_{nn}$. Conclude as before. $\blacksquare$

For example, $\det\begin{bmatrix} 2 & 7 & -1\\ 0 & -3 & 4\\ 0 & 0 & 5\end{bmatrix} = 2(-3)(5) = -30$.

**A zero row or column.** If an entire row or column is zero, the cofactor expansion along it is a sum of zeros, so **$\det A = 0$.** Unfortunately, most cofactor expansions are not so quick to evaluate.

> **💡 Why this matters:** an echelon form of a square matrix is upper triangular, so its determinant is just the product of its pivots (zero if there are fewer than $n$ pivots). §3.2 will track how row operations change the determinant, and that gives the fast method.

> **📝 Numerical Note.** By today's standards a $25\times25$ matrix is small. Yet a $25\times25$ determinant **cannot** be computed by cofactor expansion. In general, a cofactor expansion takes more than $n!$ multiplications. (An $n\times n$ expansion multiplies $n$ entries by $n$ cofactors, each an $(n-1)\times(n-1)$ expansion. If $m_n$ counts the multiplications, then $m_2 = 2$ and $m_n = n(m_{n-1}+1) > n\,m_{n-1}$, so $m_n > n!$ for $n\ge3$; in fact $m_n \approx (e-1)\,n!$.) And $25! \approx 1.5\times10^{25}$, so $m_{25}\approx 2.7\times10^{25}$. At one trillion multiplications per second, that is about 850,000 years. Faster methods come in §3.2.

> **💡 A $3\times3$ shortcut (not for $4\times4$!).** Copy the first two columns to the right of the matrix. Add the three down-right diagonal products and subtract the three up-right diagonal products. This reproduces exactly the six terms of formula (2). **It does not generalize** in any reasonable way to $4\times4$ or larger matrices (a $4\times4$ determinant has 24 terms, not 8).

### Practice Problem (worked)

*Compute*
$$
\begin{vmatrix} 5 & -7 & 2 & 2\\ 0 & 3 & 0 & -4\\ -5 & -8 & 0 & 3\\ 0 & 5 & 0 & -6\end{vmatrix}.
$$

Use the zeros. Column 3 has a single nonzero entry, $2$, in position $(1,3)$. Expand down column 3 to get a $3\times3$ determinant, and expand that down its first column (one nonzero entry, $-5$, in position $(2,1)$):

$$
\begin{vmatrix} 5 & -7 & 2 & 2\\ 0 & 3 & 0 & -4\\ -5 & -8 & 0 & 3\\ 0 & 5 & 0 & -6\end{vmatrix}
= (-1)^{1+3}\,2\begin{vmatrix} 0 & 3 & -4\\ -5 & -8 & 3\\ 0 & 5 & -6\end{vmatrix}
= 2\cdot(-1)^{2+1}(-5)\begin{vmatrix} 3 & -4\\ 5 & -6\end{vmatrix}
= 2\cdot5\cdot(-18+20) = \boxed{20}.
$$

The $(-1)^{2+1}$ comes from the position $(2,1)$ of the $-5$ **in the $3\times3$ determinant**, not from its position in the original matrix.

---

## §3.2 — Properties of Determinants

The secret of determinants lies in how they change when row operations are performed. Theorem 3 generalizes the results of Exercises 19–24 in §3.1. Its proof is at the end of this section.

### Row Operations

> **📐 THEOREM 3 (Row Operations).** Let $A$ be a square matrix.
> - **a.** If a multiple of one row of $A$ is added to another row to produce a matrix $B$, then $\det B = \det A$.
> - **b.** If two rows of $A$ are interchanged to produce $B$, then $\det B = -\det A$.
> - **c.** If one row of $A$ is multiplied by $k$ to produce $B$, then $\det B = k\cdot\det A$.

The strategy: **reduce $A$ to echelon form, keeping track of the operations, then multiply the diagonal entries** (Theorem 2, §3.1).

#### Example 1 — determinant by row reduction (worked)

$$
A = \begin{bmatrix} 1 & -4 & 2\\ -2 & 8 & -9\\ -1 & 7 & 0\end{bmatrix}.
$$

The two row replacements in column 1 do not change the determinant:
$$
\det A = \begin{vmatrix} 1 & -4 & 2\\ -2 & 8 & -9\\ -1 & 7 & 0\end{vmatrix}
= \begin{vmatrix} 1 & -4 & 2\\ 0 & 0 & -5\\ -1 & 7 & 0\end{vmatrix}
= \begin{vmatrix} 1 & -4 & 2\\ 0 & 0 & -5\\ 0 & 3 & 2\end{vmatrix}.
$$
An interchange of rows 2 and 3 reverses the sign:
$$
\det A = -\begin{vmatrix} 1 & -4 & 2\\ 0 & 3 & 2\\ 0 & 0 & -5\end{vmatrix} = -(1)(3)(-5) = \boxed{15}.
$$

**Factoring out a common multiple of one row.** The common use of Theorem 3(c) in hand calculation runs backward: pull a common factor out of a row.
$$
\begin{vmatrix} * & * & *\\ 5k & -2k & 3k\\ * & * & *\end{vmatrix}
= k\begin{vmatrix} * & * & *\\ 5 & -2 & 3\\ * & * & *\end{vmatrix},
$$
where the starred entries are unchanged.

#### Example 2 — factoring out a 2 to get a leading 1 (worked)

$$
A = \begin{bmatrix} 2 & -8 & 6 & 8\\ 3 & -9 & 5 & 10\\ -3 & 0 & 1 & -2\\ 1 & -4 & 0 & 6\end{bmatrix}.
$$

To get a 1 in the upper-left corner we could interchange rows 1 and 4. Instead, factor 2 out of row 1, then do the row replacements in column 1:
$$
\det A = 2\begin{vmatrix} 1 & -4 & 3 & 4\\ 3 & -9 & 5 & 10\\ -3 & 0 & 1 & -2\\ 1 & -4 & 0 & 6\end{vmatrix}
= 2\begin{vmatrix} 1 & -4 & 3 & 4\\ 0 & 3 & -4 & -2\\ 0 & -12 & 10 & 10\\ 0 & 0 & -3 & 2\end{vmatrix}.
$$
Use the 3 in column 2 as a pivot: add 4 times row 2 to row 3. Then add $-\tfrac12$ times row 3 to row 4:
$$
\det A = 2\begin{vmatrix} 1 & -4 & 3 & 4\\ 0 & 3 & -4 & -2\\ 0 & 0 & -6 & 2\\ 0 & 0 & -3 & 2\end{vmatrix}
= 2\begin{vmatrix} 1 & -4 & 3 & 4\\ 0 & 3 & -4 & -2\\ 0 & 0 & -6 & 2\\ 0 & 0 & 0 & 1\end{vmatrix}
= 2\cdot(1)(3)(-6)(1) = \boxed{-36}.
$$

> **⚠ Watch for:** scaling a row to make a pivot equal to 1 **changes the determinant**. In row reduction for solving systems that was harmless; here every scaling must be paid for with a factor in front. The safest habit is to use only replacements and interchanges, and to scale only by *factoring out*.

### The Determinant and Invertibility

Suppose a square matrix $A$ has been reduced to an echelon form $U$ by row replacements and row interchanges only. (This is always possible: the row reduction algorithm of §1.2 never needs scaling to reach an echelon form.) If there are $r$ interchanges, Theorem 3 gives
$$\det A = (-1)^r\det U.$$
Since $U$ is a square echelon form, it is upper triangular, so $\det U = u_{11}u_{22}\cdots u_{nn}$.

- If $A$ is invertible, $A$ has $n$ pivot positions (Invertible Matrix Theorem). A square echelon form with $n$ pivots has them on the diagonal, so $u_{11},\dots,u_{nn}$ are all pivots and all nonzero. (They need not be 1's, since $U$ was not scaled.)
- If $A$ is not invertible, $U$ has fewer than $n$ pivots, so it has a row of zeros. That row is at the bottom, so $u_{nn} = 0$ and the product is zero.

Thus

$$
\det A = \begin{cases} (-1)^r\cdot\big(\text{product of pivots in } U\big) & \text{when } A \text{ is invertible}\\[4pt] 0 & \text{when } A \text{ is not invertible}\end{cases} \tag{1}
$$

$$
U = \begin{bmatrix} \blacksquare & * & * & *\\ 0 & \blacksquare & * & *\\ 0 & 0 & \blacksquare & *\\ 0 & 0 & 0 & \blacksquare\end{bmatrix}\ (\det U\ne0)
\qquad
U = \begin{bmatrix} \blacksquare & * & * & *\\ 0 & \blacksquare & * & *\\ 0 & 0 & 0 & \blacksquare\\ 0 & 0 & 0 & 0\end{bmatrix}\ (\det U = 0)
$$

> **💡** The echelon form $U$ is not unique (it is not fully reduced), and neither are its pivots. But by (1) the **product** of the pivots is unique, up to sign.

Formula (1) is a concrete interpretation of $\det A$, and it proves the main theorem of the section.

> **📐 THEOREM 4.** A square matrix $A$ is invertible if and only if $\det A \ne 0$.

> **🔎 Proof.** By (1), $\det A$ is $\pm$ a product of $n$ nonzero pivots when $A$ is invertible, so $\det A\ne0$; and $\det A = 0$ when $A$ is not invertible. $\blacksquare$

Theorem 4 adds the statement **"$\det A \ne 0$"** to the Invertible Matrix Theorem. Two useful corollaries:

- $\det A = 0$ when the **columns** of $A$ are linearly dependent (then $A$ is not invertible, by the IMT).
- $\det A = 0$ when the **rows** of $A$ are linearly dependent. (The rows of $A$ are the columns of $A^T$. Dependent columns make $A^T$ singular, and when $A^T$ is singular, so is $A$, by the IMT.)

In practice, dependence is obvious when **two rows or two columns are equal**, or when **a row or column is zero**.

#### Example 3 — spotting a zero determinant (worked)

$$
A = \begin{bmatrix} 3 & -1 & 2 & -5\\ 0 & 5 & -3 & -6\\ -6 & 7 & -7 & 4\\ -5 & -8 & 0 & 9\end{bmatrix}.
$$

Add 2 times row 1 to row 3:
$$
\det A = \det\begin{bmatrix} 3 & -1 & 2 & -5\\ 0 & 5 & -3 & -6\\ 0 & 5 & -3 & -6\\ -5 & -8 & 0 & 9\end{bmatrix} = \boxed{0},
$$
because rows 2 and 3 of the new matrix are equal.

> **📝 Numerical Notes.**
> 1. Most computer programs that compute $\det A$ for a general matrix $A$ use formula (1).
> 2. Evaluating an $n\times n$ determinant by row operations takes about $2n^3/3$ arithmetic operations. A $25\times25$ determinant needs only about 10,000 operations, a fraction of a second, against the hundreds of thousands of years for cofactor expansion (§3.1).

Computers also handle large **sparse** matrices with special routines that exploit the zeros. Zeros speed up hand computation too. The next example combines row operations with the §3.1 strategy of expanding along zeros.

#### Example 4 — row operations plus cofactor expansion (worked)

$$
A = \begin{bmatrix} 0 & 1 & 2 & -1\\ 2 & 5 & -7 & 3\\ 0 & 3 & 6 & 2\\ -2 & -5 & 4 & -2\end{bmatrix}.
$$

Use the 2 in column 1 as a pivot: add row 2 to row 4. Column 1 now has a single nonzero entry, the 2 in position $(2,1)$, so expand down column 1. The sign is $(-1)^{2+1} = -1$:
$$
\det A = \begin{vmatrix} 0 & 1 & 2 & -1\\ 2 & 5 & -7 & 3\\ 0 & 3 & 6 & 2\\ 0 & 0 & -3 & 1\end{vmatrix}
= -2\begin{vmatrix} 1 & 2 & -1\\ 3 & 6 & 2\\ 0 & -3 & 1\end{vmatrix}.
$$
Add $-3$ times row 1 to row 2, then expand down the first column:
$$
\det A = -2\begin{vmatrix} 1 & 2 & -1\\ 0 & 0 & 5\\ 0 & -3 & 1\end{vmatrix}
= (-2)(1)\begin{vmatrix} 0 & 5\\ -3 & 1\end{vmatrix} = -2\cdot(15) = \boxed{-30}.
$$
(Interchanging rows 2 and 3 of the $3\times3$ would instead give a triangular determinant: $-2\cdot(-1)\cdot(1)(-3)(5) = -30$.)

### Column Operations

Column operations act on determinants exactly as row operations do. The proof uses induction.

> **Principle of Mathematical Induction.** Let $P(n)$ be a statement that is either true or false for each natural number $n$. Then $P(n)$ is true for all $n\ge1$ provided that $P(1)$ is true and, for each natural number $k$, if $P(k)$ is true then $P(k+1)$ is true.

> **📐 THEOREM 5.** If $A$ is an $n\times n$ matrix, then $\det A^T = \det A$.

> **🔎 Proof.** For $n = 1$ the theorem is obvious. Suppose it is true for $k\times k$ determinants, and let $n = k+1$. Deleting row $j$ and column 1 of $A^T$ gives $(A_{1j})^T$, so the cofactor of $a_{1j}$ in $A$ equals the cofactor of $a_{j1}$ in $A^T$: both are $(-1)^{1+j}$ times a $k\times k$ determinant, and $\det (A_{1j})^T = \det A_{1j}$ by the induction hypothesis. Hence the cofactor expansion of $\det A$ across the first **row** equals the cofactor expansion of $\det A^T$ down the first **column**, term by term. By Step 1 of the proof of Theorem 1 (first-column expansion), which does not use this theorem, both expansions compute their determinants, so $\det A = \det A^T$. The theorem is true for $n=1$, and its truth for one value of $n$ implies its truth for the next, so by induction it holds for all $n\ge1$. $\blacksquare$

> **💡** This is Step 2 of the proof of Theorem 1 in §3.1, now stated on its own.

**Consequence.** Every statement in Theorem 3 remains true when the word *row* is replaced everywhere by *column*. A column operation on $A$ is a row operation on $A^T$, and $\det A^T = \det A$, so apply Theorem 3 to $A^T$. Column operations are useful in theory and by hand, but numerical work here sticks to row operations.

### Determinants and Matrix Products

> **📐 THEOREM 6 (Multiplicative Property).** If $A$ and $B$ are $n\times n$ matrices, then $\det AB = (\det A)(\det B)$.

The proof is at the end of the section.

#### Example 5 — verifying Theorem 6 (worked)

$$
A = \begin{bmatrix} 6 & 1\\ 3 & 2\end{bmatrix},\qquad B = \begin{bmatrix} 4 & 3\\ 1 & 2\end{bmatrix}.
$$

$$
AB = \begin{bmatrix} 6 & 1\\ 3 & 2\end{bmatrix}\begin{bmatrix} 4 & 3\\ 1 & 2\end{bmatrix} = \begin{bmatrix} 25 & 20\\ 14 & 13\end{bmatrix},
\qquad \det AB = 25\cdot13 - 20\cdot14 = 325 - 280 = 45.
$$
Since $\det A = 9$ and $\det B = 5$, $(\det A)(\det B) = 9\cdot5 = \boxed{45} = \det AB$.

> **⚠ Watch for:** Theorem 6 has **no** analogue for sums. In general $\det(A+B)\ne\det A + \det B$. For instance, with $A = B = I_2$: $\det(A + B) = \det 2I_2 = 4$, but $\det A + \det B = 2$.
>
> The same example shows a second trap: multiplying a **matrix** by $r$ multiplies **every** row by $r$, so $\det(rA) = r^n\det A$, not $r\det A$.

### A Linearity Property of the Determinant Function

For an $n\times n$ matrix $A$, regard $\det A$ as a function of the $n$ columns of $A$. If all columns but one are held fixed, $\det A$ is a **linear function** of the remaining (vector) variable. Let the $j$th column vary:
$$A = [\,\mathbf a_1\ \cdots\ \mathbf a_{j-1}\ \ \mathbf x\ \ \mathbf a_{j+1}\ \cdots\ \mathbf a_n\,],$$
and define $T:\mathbb R^n\to\mathbb R$ by
$$T(\mathbf x) = \det[\,\mathbf a_1\ \cdots\ \mathbf a_{j-1}\ \ \mathbf x\ \ \mathbf a_{j+1}\ \cdots\ \mathbf a_n\,].$$
Then
$$T(c\mathbf x) = cT(\mathbf x)\quad\text{for all scalars } c \text{ and all } \mathbf x \text{ in } \mathbb R^n \tag{2}$$
$$T(\mathbf u + \mathbf v) = T(\mathbf u) + T(\mathbf v)\quad\text{for all } \mathbf u, \mathbf v \text{ in } \mathbb R^n \tag{3}$$

> **🔎 Proof.** Expand down column $j$ (Theorem 1). The submatrices $A_{ij}$ delete column $j$, so they do not involve $\mathbf x$:
> $$T(\mathbf x) = \sum_{i=1}^n (-1)^{i+j}x_i\det A_{ij} = C_{1j}x_1 + C_{2j}x_2 + \cdots + C_{nj}x_n,$$
> where the cofactors $C_{ij}$ are fixed numbers. A function of the form $\mathbf x\mapsto c_1x_1+\cdots+c_nx_n$ satisfies (2) and (3). (Property (2) is also Theorem 3(c) for columns.) $\blacksquare$

This **multilinearity** of the determinant has many consequences studied in more advanced courses.

### Proofs of Theorems 3 and 6

In the language of elementary matrices (§2.2), $E$ is a **row replacement** if it is obtained from $I$ by adding a multiple of one row to another row, an **interchange** if obtained by interchanging two rows of $I$, and a **scale by $r$** if obtained by multiplying a row of $I$ by a nonzero scalar $r$. Since $EA$ performs on $A$ the row operation that produced $E$ from $I$, Theorem 3 can be reformulated:

> If $A$ is an $n\times n$ matrix and $E$ is an $n\times n$ elementary matrix, then $\det EA = (\det E)(\det A)$, where
> $$\det E = \begin{cases} 1 & \text{if } E \text{ is a row replacement}\\ -1 & \text{if } E \text{ is an interchange}\\ r & \text{if } E \text{ is a scale by } r\end{cases}$$

> **🔎 Proof of Theorem 3.** Write $B$ for the matrix produced from $A$ by the row operation, and let $\alpha = 1$, $-1$, or $k$ for parts (a), (b), (c). We show $\det B = \alpha\det A$ by induction on the size $n$.
>
> *Base case $n = 2$.* Let $A = \begin{bmatrix} a & b\\ c & d\end{bmatrix}$, so $\det A = ad - bc$.
> - (a) Adding $m$ times row 1 to row 2: $a(d + mb) - b(c + ma) = ad - bc$. Adding $m$ times row 2 to row 1: $(a + mc)d - (b + md)c = ad - bc$.
> - (b) $\det\begin{bmatrix} c & d\\ a & b\end{bmatrix} = cb - da = -(ad - bc)$.
> - (c) $\det\begin{bmatrix} ka & kb\\ c & d\end{bmatrix} = k(ad - bc)$, and likewise for row 2.
>
> *Inductive step.* Suppose the theorem holds for $k\times k$ matrices with $k\ge2$, and let $A$ be $n\times n$ with $n = k+1\ge3$. A row operation involves at most two rows, so some row, say row $i$, is untouched: row $i$ of $B$ equals row $i$ of $A$. Let $A_{ij}$ and $B_{ij}$ delete row $i$ and column $j$ from $A$ and $B$. The rows of $B_{ij}$ come from the rows of $A_{ij}$ by the same type of row operation (with the same $k$ in part (c)). These submatrices are $k\times k$, so the induction hypothesis gives
> $$\det B_{ij} = \alpha\cdot\det A_{ij}.$$
> Expand $\det B$ across row $i$ (Theorem 1), using $b_{ij} = a_{ij}$:
> $$
> \begin{aligned}
> \det B &= a_{i1}(-1)^{i+1}\det B_{i1} + \cdots + a_{in}(-1)^{i+n}\det B_{in}\\
> &= \alpha a_{i1}(-1)^{i+1}\det A_{i1} + \cdots + \alpha a_{in}(-1)^{i+n}\det A_{in} = \alpha\cdot\det A.
> \end{aligned}
> $$
> By induction the theorem holds for all $n\ge2$. For $n=1$, only (c) applies, and $\det[ka] = k\det[a]$. $\blacksquare$
>
> *The reformulation.* Taking $A = I_n$ (with $\det I_n = 1$, Theorem 2) shows $\det E = 1$, $-1$, or $r$ according to the type of $E$. Then Theorem 3 says $\det EA = \alpha\det A = (\det E)(\det A)$.

> **🔎 Proof of Theorem 6.** For brevity write $|A|$ for $\det A$.
>
> *If $A$ is not invertible,* then neither is $AB$. (If $AB$ had an inverse $W$, then $A(BW) = I$, and a square matrix with a right inverse is invertible by the IMT.) So $\det AB = 0$ and $(\det A)(\det B) = 0\cdot\det B = 0$, by Theorem 4.
>
> *If $A$ is invertible,* then $A$ is row equivalent to $I_n$ (IMT), so there are elementary matrices $E_1,\dots,E_p$ with
> $$A = E_pE_{p-1}\cdots E_1\cdot I_n = E_pE_{p-1}\cdots E_1.$$
> Repeated use of the reformulated Theorem 3 gives
> $$
> \begin{aligned}
> |AB| &= |E_p\cdots E_1B| = |E_p|\,|E_{p-1}\cdots E_1B| = \cdots = |E_p|\cdots|E_1|\,|B|\\
> &= \cdots = |E_p\cdots E_1|\,|B| = |A|\,|B|,
> \end{aligned}
> $$
> where the second line runs the same argument backward with $B$ replaced by $I_n$: $|E_p\cdots E_1| = |E_p|\cdots|E_1|$. $\blacksquare$

### Practice Problems (worked)

**1.** *Compute in as few steps as possible:*
$$
\begin{vmatrix} 1 & -3 & 1 & -2\\ 2 & -5 & -1 & -2\\ 0 & -4 & 5 & 1\\ -3 & 10 & -6 & 8\end{vmatrix}.
$$
Create zeros in column 1 (add $-2$ times row 1 to row 2, and $3$ times row 1 to row 4), then a row of zeros (subtract row 2 from row 4):
$$
\begin{vmatrix} 1 & -3 & 1 & -2\\ 2 & -5 & -1 & -2\\ 0 & -4 & 5 & 1\\ -3 & 10 & -6 & 8\end{vmatrix}
= \begin{vmatrix} 1 & -3 & 1 & -2\\ 0 & 1 & -3 & 2\\ 0 & -4 & 5 & 1\\ 0 & 1 & -3 & 2\end{vmatrix}
= \begin{vmatrix} 1 & -3 & 1 & -2\\ 0 & 1 & -3 & 2\\ 0 & -4 & 5 & 1\\ 0 & 0 & 0 & 0\end{vmatrix} = \boxed{0}.
$$

**2.** *Use a determinant to decide whether $\mathbf v_1, \mathbf v_2, \mathbf v_3$ are linearly independent:*
$$\mathbf v_1 = \begin{bmatrix} 5\\ -7\\ 9\end{bmatrix},\quad \mathbf v_2 = \begin{bmatrix} -3\\ 3\\ -5\end{bmatrix},\quad \mathbf v_3 = \begin{bmatrix} 2\\ -7\\ 5\end{bmatrix}.$$
Add row 1 to row 2, then expand down column 2 (entries $-3$ at $(1,2)$, $0$, and $-5$ at $(3,2)$, both on "$-$" squares):
$$
\det[\,\mathbf v_1\ \mathbf v_2\ \mathbf v_3\,] = \begin{vmatrix} 5 & -3 & 2\\ -7 & 3 & -7\\ 9 & -5 & 5\end{vmatrix}
= \begin{vmatrix} 5 & -3 & 2\\ -2 & 0 & -5\\ 9 & -5 & 5\end{vmatrix}
= -(-3)\begin{vmatrix} -2 & -5\\ 9 & 5\end{vmatrix} - (-5)\begin{vmatrix} 5 & 2\\ -2 & -5\end{vmatrix}
= 3(35) + 5(-21) = 0.
$$
By Theorem 4 the matrix $[\,\mathbf v_1\ \mathbf v_2\ \mathbf v_3\,]$ is not invertible, so its columns are **linearly dependent** (IMT).

**3.** *Let $A$ be $n\times n$ with $A^2 = I$. Show $\det A = \pm1$.*
$\det I = 1$, and by Theorem 6, $\det(AA) = (\det A)(\det A)$. So
$$1 = \det I = \det A^2 = (\det A)^2,$$
and taking square roots, $\det A = \pm1$.

---

## §3.3 — Cramer's Rule, Volume, and Linear Transformations

This section applies the theory of §§3.1–3.2 to get important theoretical formulas and a geometric interpretation of the determinant.

### Cramer's Rule

Cramer's rule is needed in a variety of theoretical calculations, for instance to study how the solution of $A\mathbf x = \mathbf b$ is affected by changes in the entries of $\mathbf b$. As a computing method it is inefficient except for $2\times2$ or perhaps $3\times3$ matrices.

**Notation.** For any $n\times n$ matrix $A$ and any $\mathbf b$ in $\mathbb R^n$, let $A_i(\mathbf b)$ be the matrix obtained from $A$ by **replacing column $i$ by the vector $\mathbf b$**:
$$A_i(\mathbf b) = [\,\mathbf a_1\ \cdots\ \underset{\text{col } i}{\mathbf b}\ \cdots\ \mathbf a_n\,].$$

> **📐 THEOREM 7 (Cramer's Rule).** Let $A$ be an invertible $n\times n$ matrix. For any $\mathbf b$ in $\mathbb R^n$, the unique solution $\mathbf x$ of $A\mathbf x = \mathbf b$ has entries given by
> $$x_i = \frac{\det A_i(\mathbf b)}{\det A},\qquad i = 1, 2, \dots, n. \tag{1}$$

> **🔎 Proof.** Let $\mathbf a_1,\dots,\mathbf a_n$ be the columns of $A$ and $\mathbf e_1,\dots,\mathbf e_n$ the columns of $I_n$. If $A\mathbf x = \mathbf b$, the column definition of matrix multiplication gives
> $$
> A\cdot I_i(\mathbf x) = A[\,\mathbf e_1\ \cdots\ \mathbf x\ \cdots\ \mathbf e_n\,] = [\,A\mathbf e_1\ \cdots\ A\mathbf x\ \cdots\ A\mathbf e_n\,] = [\,\mathbf a_1\ \cdots\ \mathbf b\ \cdots\ \mathbf a_n\,] = A_i(\mathbf b).
> $$
> By the multiplicative property (Theorem 6),
> $$(\det A)(\det I_i(\mathbf x)) = \det A_i(\mathbf b).$$
> Row $i$ of $I_i(\mathbf x)$ is $(0,\dots,0,x_i,0,\dots,0)$ with $x_i$ in position $(i,i)$, because every column other than column $i$ is a standard basis vector $\mathbf e_j$ with $j\ne i$. Expanding across row $i$ leaves $x_i\cdot(-1)^{i+i}\det I_{n-1} = x_i$. So $(\det A)\cdot x_i = \det A_i(\mathbf b)$, and since $A$ is invertible, $\det A\ne0$; divide to get (1). $\blacksquare$

#### Example 1 — Cramer's rule on a $2\times2$ system (worked)

$$
\begin{aligned} 3x_1 - 2x_2 &= 6\\ -5x_1 + 4x_2 &= 8\end{aligned}
\qquad
A = \begin{bmatrix} 3 & -2\\ -5 & 4\end{bmatrix},\quad
A_1(\mathbf b) = \begin{bmatrix} 6 & -2\\ 8 & 4\end{bmatrix},\quad
A_2(\mathbf b) = \begin{bmatrix} 3 & 6\\ -5 & 8\end{bmatrix}.
$$
Since $\det A = 12 - 10 = 2\ne0$, the system has a unique solution:
$$
x_1 = \frac{\det A_1(\mathbf b)}{\det A} = \frac{24 + 16}{2} = 20,\qquad
x_2 = \frac{\det A_2(\mathbf b)}{\det A} = \frac{24 + 30}{2} = 27.
$$
So $\boxed{(x_1, x_2) = (20, 27)}$. Check: $3(20) - 2(27) = 6$ ✓, $-5(20) + 4(27) = 8$ ✓.

### Application to Engineering

Many engineering problems, particularly in electrical engineering and control theory, are analyzed with **Laplace transforms**, which convert a system of linear differential equations into a system of linear *algebraic* equations whose coefficients involve a parameter $s$. Cramer's rule handles the parameter cleanly.

#### Example 2 — a system with a parameter (worked)

*Find the values of $s$ for which the system has a unique solution, and describe the solution.*
$$
\begin{aligned} 3sx_1 - 2x_2 &= 4\\ -6x_1 + sx_2 &= 1\end{aligned}
\qquad
A = \begin{bmatrix} 3s & -2\\ -6 & s\end{bmatrix},\quad
A_1(\mathbf b) = \begin{bmatrix} 4 & -2\\ 1 & s\end{bmatrix},\quad
A_2(\mathbf b) = \begin{bmatrix} 3s & 4\\ -6 & 1\end{bmatrix}.
$$
$$\det A = 3s^2 - 12 = 3(s+2)(s-2),$$
so the system has a unique solution precisely when $\boxed{s\ne\pm2}$. For such $s$,
$$
x_1 = \frac{\det A_1(\mathbf b)}{\det A} = \frac{4s + 2}{3(s+2)(s-2)},\qquad
x_2 = \frac{\det A_2(\mathbf b)}{\det A} = \frac{3s + 24}{3(s+2)(s-2)} = \frac{s + 8}{(s+2)(s-2)}.
$$

> **💡 Why this matters:** row reduction would force division by expressions in $s$ at every step, with a case split each time. Cramer's rule packages the whole answer as two ratios and isolates exactly where it breaks down: the zeros of $\det A$.

### A Formula for $A^{-1}$

Cramer's rule leads easily to a general formula for $A^{-1}$. The $j$th column of $A^{-1}$ is the vector $\mathbf x$ with
$$A\mathbf x = \mathbf e_j,$$
and the $i$th entry of $\mathbf x$ is the $(i,j)$-entry of $A^{-1}$. By Cramer's rule,
$$\{(i,j)\text{-entry of } A^{-1}\} = x_i = \frac{\det A_i(\mathbf e_j)}{\det A}. \tag{2}$$
Column $i$ of $A_i(\mathbf e_j)$ is $\mathbf e_j$, whose only nonzero entry is a 1 in row $j$. A cofactor expansion down column $i$ therefore leaves one term, and deleting row $j$ and column $i$ of $A_i(\mathbf e_j)$ gives $A_{ji}$ (the other columns are those of $A$):
$$\det A_i(\mathbf e_j) = (-1)^{i+j}\det A_{ji} = C_{ji}, \tag{3}$$
where $C_{ji}$ is a cofactor of $A$. So the $(i,j)$-entry of $A^{-1}$ is $C_{ji}/\det A$. **Note the subscripts are reversed.** Thus
$$
A^{-1} = \frac{1}{\det A}\begin{bmatrix} C_{11} & C_{21} & \cdots & C_{n1}\\ C_{12} & C_{22} & \cdots & C_{n2}\\ \vdots & \vdots & & \vdots\\ C_{1n} & C_{2n} & \cdots & C_{nn}\end{bmatrix}. \tag{4}
$$

> **📗 DEFINITION.** The matrix of cofactors on the right of (4) is the **adjugate** (or **classical adjoint**) of $A$, denoted $\operatorname{adj}A$. It is the **transpose** of the matrix of cofactors $[C_{ij}]$.

(The term *adjoint* has another meaning in advanced texts on linear transformations.)

> **📐 THEOREM 8 (An Inverse Formula).** Let $A$ be an invertible $n\times n$ matrix. Then
> $$A^{-1} = \frac{1}{\det A}\operatorname{adj}A.$$

> **🔎 Proof.** This restates (4), which was derived from (2) and (3) above. $\blacksquare$

> **💡** For $A = \begin{bmatrix} a & b\\ c & d\end{bmatrix}$: $C_{11} = d$, $C_{12} = -c$, $C_{21} = -b$, $C_{22} = a$, so $\operatorname{adj}A = \begin{bmatrix} d & -b\\ -c & a\end{bmatrix}$ and Theorem 8 recovers the $2\times2$ formula of §2.2 (Theorem 4 there).

#### Example 3 — inverse by the adjugate (worked)

$$
A = \begin{bmatrix} 2 & 1 & 3\\ 1 & -1 & 1\\ 1 & 4 & -2\end{bmatrix}.
$$

The nine cofactors:
$$
\begin{aligned}
C_{11} &= +\begin{vmatrix} -1 & 1\\ 4 & -2\end{vmatrix} = -2, & C_{12} &= -\begin{vmatrix} 1 & 1\\ 1 & -2\end{vmatrix} = 3, & C_{13} &= +\begin{vmatrix} 1 & -1\\ 1 & 4\end{vmatrix} = 5,\\
C_{21} &= -\begin{vmatrix} 1 & 3\\ 4 & -2\end{vmatrix} = 14, & C_{22} &= +\begin{vmatrix} 2 & 3\\ 1 & -2\end{vmatrix} = -7, & C_{23} &= -\begin{vmatrix} 2 & 1\\ 1 & 4\end{vmatrix} = -7,\\
C_{31} &= +\begin{vmatrix} 1 & 3\\ -1 & 1\end{vmatrix} = 4, & C_{32} &= -\begin{vmatrix} 2 & 3\\ 1 & 1\end{vmatrix} = 1, & C_{33} &= +\begin{vmatrix} 2 & 1\\ 1 & -1\end{vmatrix} = -3.
\end{aligned}
$$
The adjugate is the **transpose** of the cofactor matrix ($C_{12}$ goes in the $(2,1)$ position):
$$
\operatorname{adj}A = \begin{bmatrix} -2 & 14 & 4\\ 3 & -7 & 1\\ 5 & -7 & -3\end{bmatrix}.
$$
Rather than compute $\det A$ separately, multiply. This checks the cofactors **and** produces $\det A$:
$$
(\operatorname{adj}A)\,A = \begin{bmatrix} -2 & 14 & 4\\ 3 & -7 & 1\\ 5 & -7 & -3\end{bmatrix}\begin{bmatrix} 2 & 1 & 3\\ 1 & -1 & 1\\ 1 & 4 & -2\end{bmatrix} = \begin{bmatrix} 14 & 0 & 0\\ 0 & 14 & 0\\ 0 & 0 & 14\end{bmatrix} = 14I.
$$
Since $(\operatorname{adj}A)A = 14I$, the matrix $\tfrac1{14}\operatorname{adj}A$ is a left inverse of $A$, so $A$ is invertible (IMT). Theorem 8 then gives $(\operatorname{adj}A)A = (\det A)I$, so $\det A = 14$, and
$$
A^{-1} = \frac{1}{14}\begin{bmatrix} -2 & 14 & 4\\ 3 & -7 & 1\\ 5 & -7 & -3\end{bmatrix}
= \boxed{\begin{bmatrix} -1/7 & 1 & 2/7\\ 3/14 & -1/2 & 1/14\\ 5/14 & -1/2 & -3/14\end{bmatrix}}.
$$

> **⚠ Watch for:** forgetting the transpose. Putting $C_{ij}$ in position $(i,j)$ gives the cofactor matrix, not the adjugate, and the product with $A$ generally will not be a multiple of $I$. The product check catches it.

> **📝 Numerical Notes.** Theorem 8 is useful mainly for **theoretical** calculations: the formula lets one deduce properties of $A^{-1}$ without computing it. Except in special cases, the algorithm of §2.2 is a much better way to compute $A^{-1}$. Cramer's rule is likewise a theoretical tool, for example for studying how sensitive the solution of $A\mathbf x = \mathbf b$ is to changes in an entry of $\mathbf b$ or $A$ (perhaps from experimental error). For a $3\times3$ matrix with **complex** entries, Cramer's rule is sometimes chosen for hand computation, since row reducing $[\,A\ \ \mathbf b\,]$ with complex arithmetic is messy and the determinants are fairly easy. For a larger $n\times n$ matrix, real or complex, Cramer's rule is hopelessly inefficient: computing just **one** determinant takes about as much work as solving $A\mathbf x = \mathbf b$ by row reduction.

### Determinants as Area or Volume

This verifies the geometric interpretation promised in the chapter introduction. Lengths, areas, and volumes in $\mathbb R^2$ and $\mathbb R^3$ are taken in the usual Euclidean sense (Chapter 6 treats length and distance in $\mathbb R^n$).

> **📐 THEOREM 9.** If $A$ is a $2\times2$ matrix, the area of the parallelogram determined by the columns of $A$ is $|\det A|$. If $A$ is a $3\times3$ matrix, the volume of the parallelepiped determined by the columns of $A$ is $|\det A|$.

The proof rests on one geometric fact.

> **Lemma.** Let $\mathbf a_1$ and $\mathbf a_2$ be nonzero vectors. Then for any scalar $c$, the area of the parallelogram determined by $\mathbf a_1$ and $\mathbf a_2$ equals the area of the parallelogram determined by $\mathbf a_1$ and $\mathbf a_2 + c\mathbf a_1$.

> **🔎 Proof of the Lemma.** If $\mathbf a_2$ is a multiple of $\mathbf a_1$, so is $\mathbf a_2 + c\mathbf a_1$, and both parallelograms are degenerate with area zero. Otherwise, let $L$ be the line through $\mathbf 0$ and $\mathbf a_1$. Then $\mathbf a_2 + L$ is the line through $\mathbf a_2$ parallel to $L$, and $\mathbf a_2 + c\mathbf a_1$ lies on it. So $\mathbf a_2$ and $\mathbf a_2 + c\mathbf a_1$ are the same perpendicular distance from $L$. The two parallelograms share the base from $\mathbf 0$ to $\mathbf a_1$ and have the same height, hence the same area. $\blacksquare$

> **🔎 Proof of Theorem 9 ($\mathbb R^2$).**
> - *Diagonal matrices.* $\left|\det\begin{bmatrix} a & 0\\ 0 & d\end{bmatrix}\right| = |ad|$, the area of the rectangle with sides $|a|$ and $|d|$.
> - *Singular $A$.* The columns are dependent, so the parallelogram lies on a line and has area $0 = |\det A|$ (Theorem 4).
> - *Invertible $A$.* Transform $A$ into a diagonal matrix using only **column interchanges** and **column replacements**. (Do it as row operations on $A^T$: reduce $A^T$ to echelon form without scaling; its two pivots are nonzero and on the diagonal; then one more replacement clears the entry above the second pivot.) By §3.2, neither operation changes $|\det A|$: replacements keep $\det$, interchanges flip only its sign. Neither operation changes the area: an interchange leaves the parallelogram itself unchanged, and a replacement leaves the area unchanged by the Lemma (with the roles of $\mathbf a_1$ and $\mathbf a_2$ swapped if needed, since the parallelogram on $\mathbf a_1,\mathbf a_2$ is the one on $\mathbf a_2,\mathbf a_1$; the columns stay nonzero because each operation keeps the matrix invertible). So $|\det A|$ = area holds for $A$ because it holds for the diagonal matrix at the end. $\blacksquare$

> **🔎 Proof of Theorem 9 ($\mathbb R^3$).** The argument is the same. For a diagonal matrix with diagonal $a, b, c$, $|\det A| = |abc|$, the volume of a box. A singular $A$ has coplanar columns, so the parallelepiped is flat with volume $0$. An invertible $3\times3$ matrix becomes diagonal by column interchanges and replacements (row operations on $A^T$). Interchanges do not change the solid. For a replacement, relabel so that it is $[\,\mathbf a_1\ \mathbf a_2\ \mathbf a_3\,]\to[\,\mathbf a_1\ \ \mathbf a_2 + c\mathbf a_1\ \ \mathbf a_3\,]$. The volume of the parallelepiped is the area of its base, the parallelogram on $\mathbf a_1, \mathbf a_3$ (independent, since $A$ is invertible) in the plane $\operatorname{Span}\{\mathbf a_1, \mathbf a_3\}$, times the altitude of $\mathbf a_2$ above that plane. The vector $\mathbf a_2 + c\mathbf a_1$ lies in the plane $\mathbf a_2 + \operatorname{Span}\{\mathbf a_1, \mathbf a_3\}$, which is parallel to $\operatorname{Span}\{\mathbf a_1,\mathbf a_3\}$, so it has the same altitude. The base is unchanged, so the volume is unchanged. $\blacksquare$

#### Example 4 — area of a parallelogram not at the origin (worked)

*Find the area of the parallelogram with vertices $(-2,-2)$, $(0,3)$, $(4,-1)$, and $(6,4)$.*

Translate the parallelogram so that a vertex is at the origin: subtract $(-2,-2)$ from each vertex. Translation does not change area. The new vertices are $(0,0)$, $(2,5)$, $(6,1)$, and $(8,6) = (2,5) + (6,1)$, so the parallelogram is determined by the columns of
$$A = \begin{bmatrix} 2 & 6\\ 5 & 1\end{bmatrix}.$$
Since $|\det A| = |2 - 30| = |-28|$, the area is $\boxed{28}$.

> **⚠ Watch for:** feeding the original vertices straight into a determinant. Only vectors **from one vertex** to its two neighbors determine the parallelogram. Translate first, and check that the fourth vertex is the sum of the two edge vectors, which identifies the opposite corner.

### Linear Transformations

Determinants describe an important geometric property of linear transformations of $\mathbb R^2$ and $\mathbb R^3$. If $T$ is a linear transformation and $S$ is a set in its domain, let $T(S)$ be the set of images of points of $S$. How does the area (volume) of $T(S)$ compare with that of $S$? For convenience, a region bounded by a parallelogram is also called a parallelogram.

> **📐 THEOREM 10.** Let $T:\mathbb R^2\to\mathbb R^2$ be the linear transformation determined by a $2\times2$ matrix $A$. If $S$ is a parallelogram in $\mathbb R^2$, then
> $$\{\text{area of } T(S)\} = |\det A|\cdot\{\text{area of } S\}. \tag{5}$$
> If $T$ is determined by a $3\times3$ matrix $A$, and if $S$ is a parallelepiped in $\mathbb R^3$, then
> $$\{\text{volume of } T(S)\} = |\det A|\cdot\{\text{volume of } S\}. \tag{6}$$

> **🔎 Proof.** *A parallelogram at the origin.* Let $S$ be determined by $\mathbf b_1$ and $\mathbf b_2$:
> $$S = \{s_1\mathbf b_1 + s_2\mathbf b_2 : 0\le s_1\le1,\ 0\le s_2\le1\}.$$
> By linearity, the image of $S$ consists of the points
> $$T(s_1\mathbf b_1 + s_2\mathbf b_2) = s_1T(\mathbf b_1) + s_2T(\mathbf b_2) = s_1A\mathbf b_1 + s_2A\mathbf b_2,\qquad 0\le s_1, s_2\le1.$$
> So $T(S)$ is the parallelogram determined by the columns of $[\,A\mathbf b_1\ \ A\mathbf b_2\,] = AB$, where $B = [\,\mathbf b_1\ \ \mathbf b_2\,]$. By Theorem 9 and the multiplicative property,
> $$\{\text{area of } T(S)\} = |\det AB| = |\det A|\cdot|\det B| = |\det A|\cdot\{\text{area of } S\}. \tag{7}$$
> *An arbitrary parallelogram* has the form $\mathbf p + S$ with $S$ at the origin as above. By linearity $T(\mathbf p + \mathbf s) = T(\mathbf p) + T(\mathbf s)$, so $T$ maps $\mathbf p + S$ onto $T(\mathbf p) + T(S)$. Translation does not change area, so
> $$
> \begin{aligned}
> \{\text{area of } T(\mathbf p + S)\} &= \{\text{area of } T(\mathbf p) + T(S)\} = \{\text{area of } T(S)\} && \text{(translation)}\\
> &= |\det A|\cdot\{\text{area of } S\} && \text{(by (7))}\\
> &= |\det A|\cdot\{\text{area of } \mathbf p + S\} && \text{(translation)}.
> \end{aligned}
> $$
> This proves (5). For (6), take $S = \{s_1\mathbf b_1 + s_2\mathbf b_2 + s_3\mathbf b_3 : 0\le s_i\le1\}$; the same argument with three vectors and the $3\times3$ case of Theorem 9 applies word for word. $\blacksquare$

> **💡 Why this matters:** $|\det A|$ is the **area (volume) scaling factor** of $\mathbf x\mapsto A\mathbf x$, the same factor for every parallelogram, wherever it sits. A singular $A$ has factor $0$: it flattens the plane onto a line or a point, which is exactly why it cannot be undone.

**Beyond parallelograms.** For a region not bounded by straight lines or planes, area itself must first be defined, which is a calculus question; here is the idea in $\mathbb R^2$. A planar region $R$ with finite area can be approximated by a grid of small squares inside $R$, and as the squares shrink, the total area of the squares approaches the area of $R$. Under $T$, each small square maps to a parallelogram of $|\det A|$ times its area (Theorem 10). So if $R'$ is the union of the squares inside $R$, the area of $T(R')$ is exactly $|\det A|$ times the area of $R'$. And the area of $T(R')$ is close to the area of $T(R)$. A limiting argument then justifies:

> **The conclusions of Theorem 10 hold whenever $S$ is a region in $\mathbb R^2$ with finite area or a region in $\mathbb R^3$ with finite volume.**

> **💡** This is the linear case of the **Jacobian**. For a nonlinear map, $|\det|$ of the derivative matrix is the local area scaling factor, which is why it appears in the change-of-variables formula for multiple integrals.

#### Example 5 — the area of an ellipse (worked)

*Let $a, b > 0$. Find the area of the region $E$ bounded by the ellipse*
$$\frac{x_1^2}{a^2} + \frac{x_2^2}{b^2} = 1.$$

Claim: $E$ is the image of the unit disk $D$ under the linear transformation determined by
$$A = \begin{bmatrix} a & 0\\ 0 & b\end{bmatrix}.$$
If $\mathbf u = \begin{bmatrix} u_1\\ u_2\end{bmatrix}$, $\mathbf x = \begin{bmatrix} x_1\\ x_2\end{bmatrix}$, and $\mathbf x = A\mathbf u$, then
$$u_1 = \frac{x_1}{a},\qquad u_2 = \frac{x_2}{b}.$$
So $\mathbf u$ is in the unit disk, $u_1^2 + u_2^2\le1$, if and only if $\mathbf x$ is in $E$, $(x_1/a)^2 + (x_2/b)^2\le1$. By the generalization of Theorem 10,
$$
\{\text{area of ellipse}\} = \{\text{area of } T(D)\} = |\det A|\cdot\{\text{area of } D\} = ab\cdot\pi(1)^2 = \boxed{\pi ab}.
$$
(When $a = b = r$ this is the area $\pi r^2$ of a circle.)

### Practice Problem (worked)

*Let $S$ be the parallelogram determined by $\mathbf b_1 = \begin{bmatrix} 1\\ 3\end{bmatrix}$ and $\mathbf b_2 = \begin{bmatrix} 5\\ 1\end{bmatrix}$, and let $A = \begin{bmatrix} 1 & -0.1\\ 0 & 2\end{bmatrix}$. Compute the area of the image of $S$ under $\mathbf x\mapsto A\mathbf x$.*

The area of $S$ is $\left|\det\begin{bmatrix} 1 & 5\\ 3 & 1\end{bmatrix}\right| = |1 - 15| = 14$, and $\det A = 2$ (triangular). By Theorem 10,
$$\{\text{area of the image}\} = |\det A|\cdot\{\text{area of } S\} = 2\cdot14 = \boxed{28}.$$
