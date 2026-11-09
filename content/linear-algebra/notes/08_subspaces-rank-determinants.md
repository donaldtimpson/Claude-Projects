# Linear Algebra — Lecture Notes

**Text:** Lay, *Linear Algebra and Its Applications*, 5th ed.
**Chapters 2–3 — Matrix Algebra; Determinants**
**Sections covered:** 2.8 Subspaces of $\mathbb R^n$ · 2.9 Dimension and Rank · 3.1 Introduction to Determinants

> *Roadmap:* §2.8 names the sets of vectors that have been appearing since Chapter 1: **subspaces**, sets closed under addition and scalar multiplication. Every matrix carries two of them, its **column space** (where $A\mathbf x = \mathbf b$ is solvable) and its **null space** (the solutions of $A\mathbf x = \mathbf 0$). A **basis** is the most efficient way to describe a subspace. §2.9 uses a basis to put **coordinates** on a subspace, counts basis vectors to get **dimension** and **rank**, proves the **Rank Theorem** $\operatorname{rank}A + \dim\operatorname{Nul}A = n$, and adds six more statements to the Invertible Matrix Theorem. §3.1 opens Chapter 3: it extends the $2\times2$ determinant $ad-bc$ to $n\times n$ matrices by a recursive **cofactor expansion**. §3.2 (properties of determinants, and $\det A\ne0 \iff A$ invertible) comes next.

---

## §2.8 — Subspaces of $\mathbb R^n$

Subspaces often arise in connection with some matrix $A$, and they give useful information about the equation $A\mathbf x = \mathbf b$. The terms in this section are used throughout the rest of the course.

### Core Definitions

> **📗 DEFINITION.** A **subspace** of $\mathbb R^n$ is any set $H$ in $\mathbb R^n$ that has three properties:
> - **a.** The zero vector is in $H$.
> - **b.** For each $\mathbf u$ and $\mathbf v$ in $H$, the sum $\mathbf u + \mathbf v$ is in $H$.
> - **c.** For each $\mathbf u$ in $H$ and each scalar $c$, the vector $c\mathbf u$ is in $H$.

In words, a subspace is **closed under addition and scalar multiplication.** Most sets of vectors from Chapter 1 are subspaces. The standard picture is a **plane through the origin** in $\mathbb R^3$.

#### Example 1 — a span of two vectors is a subspace (worked)

*If $\mathbf v_1$ and $\mathbf v_2$ are in $\mathbb R^n$ and $H = \operatorname{Span}\{\mathbf v_1, \mathbf v_2\}$, then $H$ is a subspace of $\mathbb R^n$.*

- **(a)** $\mathbf 0 = 0\mathbf v_1 + 0\mathbf v_2$ is a linear combination of $\mathbf v_1, \mathbf v_2$, so $\mathbf 0 \in H$.
- **(b)** Take two arbitrary vectors in $H$, say $\mathbf u = s_1\mathbf v_1 + s_2\mathbf v_2$ and $\mathbf v = t_1\mathbf v_1 + t_2\mathbf v_2$. Then
$$\mathbf u + \mathbf v = (s_1+t_1)\mathbf v_1 + (s_2+t_2)\mathbf v_2,$$
a linear combination of $\mathbf v_1, \mathbf v_2$, so $\mathbf u+\mathbf v \in H$.
- **(c)** For any scalar $c$, $c\mathbf u = c(s_1\mathbf v_1 + s_2\mathbf v_2) = (cs_1)\mathbf v_1 + (cs_2)\mathbf v_2 \in H$.

So $H$ is a subspace. If $\mathbf v_1 \ne \mathbf 0$ and $\mathbf v_2 = k\mathbf v_1$, then $\mathbf v_1, \mathbf v_2$ span only a **line** through the origin, so a line through the origin is also a subspace.

#### Example 2 — a line *not* through the origin is not a subspace

A line $L$ not through the origin fails property (a): it does not contain $\mathbf 0$. It also fails (b) and (c). If $\mathbf u, \mathbf v$ are on $L$, the parallelogram rule puts $\mathbf u + \mathbf v$ off the line. If $\mathbf w$ is on $L$, then $2\mathbf w$ is off it.

> **⚠ Watch for:** checking $\mathbf 0 \in H$ first is the fastest way to *rule out* a subspace. But passing that test proves nothing by itself. The union of two **different** lines through $\mathbf 0$ contains $\mathbf 0$ and is closed under scaling, yet it fails (b).

#### Example 3 — every span is a subspace

*For $\mathbf v_1,\dots,\mathbf v_p$ in $\mathbb R^n$, the set $\operatorname{Span}\{\mathbf v_1,\dots,\mathbf v_p\}$ of all linear combinations of $\mathbf v_1,\dots,\mathbf v_p$ is a subspace of $\mathbb R^n$.*

> **🔎 Proof.** $\mathbf 0 = 0\mathbf v_1 + \cdots + 0\mathbf v_p$ is in the span. If $\mathbf u = \sum s_i\mathbf v_i$ and $\mathbf v = \sum t_i\mathbf v_i$, then $\mathbf u + \mathbf v = \sum (s_i + t_i)\mathbf v_i$ and $c\mathbf u = \sum (cs_i)\mathbf v_i$. Both are linear combinations of $\mathbf v_1,\dots,\mathbf v_p$. $\blacksquare$

We now call $\operatorname{Span}\{\mathbf v_1,\dots,\mathbf v_p\}$ **the subspace spanned** (or **generated**) by $\mathbf v_1,\dots,\mathbf v_p$.

**Two special subspaces.** $\mathbb R^n$ is a subspace of itself. The set containing only the zero vector of $\mathbb R^n$ is the **zero subspace**, $\{\mathbf 0\}$: $\mathbf 0 + \mathbf 0 = \mathbf 0$ and $c\mathbf 0 = \mathbf 0$.

### Column Space and Null Space of a Matrix

Subspaces usually arise in one of two ways, and in both cases the subspace is tied to a matrix.

> **📗 DEFINITION.** The **column space** of a matrix $A$ is the set $\operatorname{Col}A$ of all linear combinations of the columns of $A$.

If $A = [\,\mathbf a_1\ \cdots\ \mathbf a_n\,]$ with columns in $\mathbb R^m$, then $\operatorname{Col}A = \operatorname{Span}\{\mathbf a_1,\dots,\mathbf a_n\}$. By Example 3, **the column space of an $m\times n$ matrix is a subspace of $\mathbb R^m$.** $\operatorname{Col}A = \mathbb R^m$ only when the columns of $A$ span $\mathbb R^m$. Otherwise $\operatorname{Col}A$ is only part of $\mathbb R^m$.

#### Example 4 — is $\mathbf b$ in $\operatorname{Col}A$? (worked)

$$
A = \begin{bmatrix} 1 & -3 & -4\\ -4 & 6 & -2\\ -3 & 7 & 6\end{bmatrix},\qquad
\mathbf b = \begin{bmatrix} 3\\ 3\\ -4\end{bmatrix}.
$$

$\mathbf b$ is a linear combination of the columns of $A$ exactly when $\mathbf b = A\mathbf x$ for some $\mathbf x$, that is, when $A\mathbf x = \mathbf b$ is consistent. Row reduce $[\,A\ \ \mathbf b\,]$:

$$
\begin{bmatrix} 1 & -3 & -4 & 3\\ -4 & 6 & -2 & 3\\ -3 & 7 & 6 & -4\end{bmatrix}
\sim
\begin{bmatrix} 1 & -3 & -4 & 3\\ 0 & -6 & -18 & 15\\ 0 & -2 & -6 & 5\end{bmatrix}
\sim
\begin{bmatrix} 1 & -3 & -4 & 3\\ 0 & -6 & -18 & 15\\ 0 & 0 & 0 & 0\end{bmatrix}.
$$

No $[\,0\ 0\ 0\mid b\,]$ row with $b\ne0$, so $A\mathbf x = \mathbf b$ is **consistent** and **$\mathbf b \in \operatorname{Col}A$.** For explicit weights, take the free variable $x_3 = 0$: then $x_2 = -\tfrac52$ and $x_1 = 3 + 3x_2 = -\tfrac92$. Check: $-\tfrac92(1,-4,-3) - \tfrac52(-3,6,7) = (3,3,-4)$ ✓.

> **💡 Why this matters:** when a system is written $A\mathbf x = \mathbf b$, **$\operatorname{Col}A$ is the set of all $\mathbf b$ for which the system has a solution.** The existence question from Chapter 1 has become a question about a subspace.

> **📗 DEFINITION.** The **null space** of a matrix $A$ is the set $\operatorname{Nul}A$ of all solutions of the homogeneous equation $A\mathbf x = \mathbf 0$.

When $A$ has $n$ columns, the solutions of $A\mathbf x = \mathbf 0$ are in $\mathbb R^n$, so $\operatorname{Nul}A$ is a subset of $\mathbb R^n$. In fact it is a subspace:

> **📐 THEOREM 12.** The null space of an $m\times n$ matrix $A$ is a subspace of $\mathbb R^n$. Equivalently, the set of all solutions of a system $A\mathbf x = \mathbf 0$ of $m$ homogeneous linear equations in $n$ unknowns is a subspace of $\mathbb R^n$.

> **🔎 Proof.** The zero vector is in $\operatorname{Nul}A$, because $A\mathbf 0 = \mathbf 0$. Take any $\mathbf u$ and $\mathbf v$ in $\operatorname{Nul}A$, so $A\mathbf u = \mathbf 0$ and $A\mathbf v = \mathbf 0$. By a property of matrix multiplication,
> $$A(\mathbf u + \mathbf v) = A\mathbf u + A\mathbf v = \mathbf 0 + \mathbf 0 = \mathbf 0,$$
> so $\mathbf u + \mathbf v$ satisfies $A\mathbf x = \mathbf 0$ and is in $\operatorname{Nul}A$. For any scalar $c$, $A(c\mathbf u) = c(A\mathbf u) = c\mathbf 0 = \mathbf 0$, so $c\mathbf u$ is in $\operatorname{Nul}A$. $\blacksquare$

**Implicit vs. explicit.** To test whether a given $\mathbf v$ is in $\operatorname{Nul}A$, compute $A\mathbf v$ and see whether it is $\mathbf 0$. $\operatorname{Nul}A$ is defined **implicitly**, by a condition each vector must be checked against. $\operatorname{Col}A$ is defined **explicitly**: its vectors are *built* as linear combinations of the columns. To get an explicit description of $\operatorname{Nul}A$, solve $A\mathbf x = \mathbf 0$ and write the solution in parametric vector form (Example 6).

> **⚠ Watch for:** for an $m\times n$ matrix, $\operatorname{Col}A$ lives in $\mathbb R^{m}$ (columns have $m$ entries) and $\operatorname{Nul}A$ lives in $\mathbb R^{n}$ (inputs $\mathbf x$ have $n$ entries). When $m \ne n$ they are not even in the same space.

### Basis for a Subspace

A subspace usually contains infinitely many vectors, so it is handled best by a small finite set that spans it. The smaller the set, the better, and the smallest possible spanning set must be linearly independent:

> **📐 Lemma (trimming a spanning set).** If $p\ge2$ and $\{\mathbf v_1,\dots,\mathbf v_p\}$ spans $H$ and is linearly dependent, then some $\mathbf v_k$ can be removed and the remaining $p-1$ vectors still span $H$. So a spanning set of $H$ with the fewest possible vectors is linearly independent.

> **🔎 Proof.** Dependence gives weights, not all zero, with $c_1\mathbf v_1 + \cdots + c_p\mathbf v_p = \mathbf 0$. Pick $k$ with $c_k\ne0$ and solve:
> $$\mathbf v_k = -\frac{1}{c_k}\sum_{i\ne k} c_i\mathbf v_i .$$
> Any $\mathbf x$ in $H$ is a combination $\sum_i d_i\mathbf v_i$. Substitute the expression for $\mathbf v_k$; the result is a combination of the $\mathbf v_i$ with $i\ne k$ alone. So those $p-1$ vectors still span $H$. A spanning set that cannot be shortened therefore cannot be dependent. $\blacksquare$

> **📗 DEFINITION.** A **basis** for a subspace $H$ of $\mathbb R^n$ is a linearly independent set in $H$ that spans $H$.

#### Example 5 — the standard basis

The columns of an invertible $n\times n$ matrix form a basis for all of $\mathbb R^n$: they are linearly independent and span $\mathbb R^n$, by the Invertible Matrix Theorem (statements (e) and (h)). One such matrix is $I_n$, whose columns are

$$
\mathbf e_1 = \begin{bmatrix}1\\0\\\vdots\\0\end{bmatrix},\quad
\mathbf e_2 = \begin{bmatrix}0\\1\\\vdots\\0\end{bmatrix},\quad\dots,\quad
\mathbf e_n = \begin{bmatrix}0\\\vdots\\0\\1\end{bmatrix}.
$$

$\{\mathbf e_1,\dots,\mathbf e_n\}$ is the **standard basis** for $\mathbb R^n$.

#### Example 6 — a basis for $\operatorname{Nul}A$ (worked)

$$
A = \begin{bmatrix} -3 & 6 & -1 & 1 & -7\\ 1 & -2 & 2 & 3 & -1\\ 2 & -4 & 5 & 8 & -4\end{bmatrix}.
$$

Solve $A\mathbf x = \mathbf 0$ in parametric vector form:

$$
[\,A\ \ \mathbf 0\,] \sim
\begin{bmatrix} 1 & -2 & 0 & -1 & 3 & 0\\ 0 & 0 & 1 & 2 & -2 & 0\\ 0 & 0 & 0 & 0 & 0 & 0\end{bmatrix}
\qquad
\begin{aligned} x_1 - 2x_2 \phantom{{}+x_3} - x_4 + 3x_5 &= 0\\ x_3 + 2x_4 - 2x_5 &= 0\\ 0 &= 0\end{aligned}
$$

General solution: $x_1 = 2x_2 + x_4 - 3x_5$, $x_3 = -2x_4 + 2x_5$, with $x_2, x_4, x_5$ free.

$$
\begin{bmatrix}x_1\\x_2\\x_3\\x_4\\x_5\end{bmatrix}
= \begin{bmatrix}2x_2 + x_4 - 3x_5\\ x_2\\ -2x_4 + 2x_5\\ x_4\\ x_5\end{bmatrix}
= x_2\underbrace{\begin{bmatrix}2\\1\\0\\0\\0\end{bmatrix}}_{\mathbf u}
+ x_4\underbrace{\begin{bmatrix}1\\0\\-2\\1\\0\end{bmatrix}}_{\mathbf v}
+ x_5\underbrace{\begin{bmatrix}-3\\0\\2\\0\\1\end{bmatrix}}_{\mathbf w}
= x_2\mathbf u + x_4\mathbf v + x_5\mathbf w. \tag{1}
$$

Equation (1) shows that $\operatorname{Nul}A$ is exactly the set of all linear combinations of $\mathbf u, \mathbf v, \mathbf w$, so $\{\mathbf u, \mathbf v, \mathbf w\}$ **spans** $\operatorname{Nul}A$. It is also **linearly independent**: look at entries 2, 4, and 5 of $x_2\mathbf u + x_4\mathbf v + x_5\mathbf w$. They are $x_2$, $x_4$, $x_5$, so the combination is $\mathbf 0$ only if $x_2 = x_4 = x_5 = 0$.

$$\boxed{\ \text{Basis for }\operatorname{Nul}A:\ \{\mathbf u, \mathbf v, \mathbf w\}\ }$$

> **💡 Why this matters:** the standard parametric-vector-form procedure **automatically** produces a basis for $\operatorname{Nul}A$, with one basis vector per free variable. The same entry-reading argument works for every matrix: the vector attached to free variable $x_k$ has a $1$ in entry $k$, and every other vector has a $0$ there. This fact is used throughout Chapter 5.

Finding a basis for the column space is actually *less* work, but the method needs explanation. Start with a matrix already in reduced echelon form.

#### Example 7 — a basis for $\operatorname{Col}B$, $B$ in reduced echelon form (worked)

$$
B = [\,\mathbf b_1\ \cdots\ \mathbf b_5\,] = \begin{bmatrix} 1 & 0 & -3 & 5 & 0\\ 0 & 1 & 2 & -1 & 0\\ 0 & 0 & 0 & 0 & 1\\ 0 & 0 & 0 & 0 & 0\end{bmatrix}.
$$

By inspection, $\mathbf b_3 = -3\mathbf b_1 + 2\mathbf b_2$ and $\mathbf b_4 = 5\mathbf b_1 - \mathbf b_2$. So any vector in $\operatorname{Col}B$,
$$\mathbf v = c_1\mathbf b_1 + c_2\mathbf b_2 + c_3\mathbf b_3 + c_4\mathbf b_4 + c_5\mathbf b_5
= c_1\mathbf b_1 + c_2\mathbf b_2 + c_3(-3\mathbf b_1 + 2\mathbf b_2) + c_4(5\mathbf b_1 - \mathbf b_2) + c_5\mathbf b_5,$$
is a linear combination of $\mathbf b_1, \mathbf b_2, \mathbf b_5$ alone. So $\{\mathbf b_1, \mathbf b_2, \mathbf b_5\}$ spans $\operatorname{Col}B$. These three are columns of an identity matrix ($\mathbf e_1, \mathbf e_2, \mathbf e_3$ of $\mathbb R^4$), so they are linearly independent.

$$\boxed{\ \text{Basis for }\operatorname{Col}B:\ \{\mathbf b_1, \mathbf b_2, \mathbf b_5\}\text{, the pivot columns of }B\ }$$

**The key fact for a general $A$.** A linear dependence relation among the columns of $A$ is an equation $A\mathbf x = \mathbf 0$ (columns not involved get weight $0$ in $\mathbf x$). If $A$ is row reduced to $B$, the columns change drastically, but **$A\mathbf x = \mathbf 0$ and $B\mathbf x = \mathbf 0$ have the same solution set.** So the columns of $A$ satisfy **exactly the same linear dependence relations** as the columns of $B$.

#### Example 8 — a basis for $\operatorname{Col}A$ (worked)

*The matrix*
$$
A = [\,\mathbf a_1\ \cdots\ \mathbf a_5\,] = \begin{bmatrix} 1 & 3 & 3 & 2 & -9\\ -2 & -2 & 2 & -8 & 2\\ 2 & 3 & 0 & 7 & 1\\ 3 & 4 & -1 & 11 & -8\end{bmatrix}
$$
*is row equivalent to $B$ in Example 7. Find a basis for $\operatorname{Col}A$.*

From Example 7, the pivot columns of $A$ are columns 1, 2, and 5. Since $\mathbf b_3 = -3\mathbf b_1 + 2\mathbf b_2$ and $\mathbf b_4 = 5\mathbf b_1 - \mathbf b_2$, and row operations do not affect dependence relations among columns,
$$\mathbf a_3 = -3\mathbf a_1 + 2\mathbf a_2 \quad\text{and}\quad \mathbf a_4 = 5\mathbf a_1 - \mathbf a_2 .$$
Check: $-3(1,-2,2,3) + 2(3,-2,3,4) = (3,2,0,-1) = \mathbf a_3$ ✓ and $5(1,-2,2,3) - (3,-2,3,4) = (2,-8,7,11) = \mathbf a_4$ ✓.

So $\mathbf a_3, \mathbf a_4$ are not needed to generate $\operatorname{Col}A$. And $\{\mathbf a_1, \mathbf a_2, \mathbf a_5\}$ is independent: any dependence relation among them would be a dependence relation among $\mathbf b_1, \mathbf b_2, \mathbf b_5$, which are independent.

$$\boxed{\ \text{Basis for }\operatorname{Col}A:\ \{\mathbf a_1, \mathbf a_2, \mathbf a_5\}\ }$$

> **📐 THEOREM 13.** The pivot columns of a matrix $A$ form a basis for the column space of $A$.

> **🔎 Proof.** Let $B$ be the reduced echelon form of $A$, with pivot columns in positions $j_1 < \cdots < j_r$. Since $A\mathbf x = \mathbf 0$ and $B\mathbf x = \mathbf 0$ have the same solutions, **a vector of weights $\mathbf x$ gives a dependence relation among the columns of $A$ exactly when it gives one among the columns of $B$.**
>
> *Independence.* In $B$, pivot column $j_i$ is $\mathbf e_i$ (a leading $1$ in row $i$, zeros elsewhere), so $\mathbf b_{j_1},\dots,\mathbf b_{j_r}$ are $\mathbf e_1,\dots,\mathbf e_r$ and are independent. Suppose $c_1\mathbf a_{j_1} + \cdots + c_r\mathbf a_{j_r} = \mathbf 0$. Let $\mathbf x$ have entry $c_i$ in position $j_i$ and $0$ elsewhere. Then $A\mathbf x = \mathbf 0$, so $B\mathbf x = \mathbf 0$, i.e., $c_1\mathbf e_1 + \cdots + c_r\mathbf e_r = \mathbf 0$. So every $c_i = 0$.
>
> *Spanning.* Let $\mathbf b_k$ be a non-pivot column of $B$. Its nonzero entries lie in rows $1,\dots,r$ (rows below $r$ are zero rows), so $\mathbf b_k = b_{1k}\mathbf e_1 + \cdots + b_{rk}\mathbf e_r = b_{1k}\mathbf b_{j_1} + \cdots + b_{rk}\mathbf b_{j_r}$. This is a dependence relation among the columns of $B$, so the same weights give one among the columns of $A$: $\mathbf a_k = b_{1k}\mathbf a_{j_1} + \cdots + b_{rk}\mathbf a_{j_r}$. Every non-pivot column of $A$ is a combination of the pivot columns. Substituting these into any combination of all the columns, as in Example 7, shows that every vector in $\operatorname{Col}A$ is a combination of the pivot columns alone.
>
> If $A$ has no pivot columns, then $B = 0$, so $A = 0$ and $\operatorname{Col}A = \{\mathbf 0\}$, which has no basis ($\{\mathbf 0\}$ is a dependent set); so the theorem concerns $A\ne0$. Otherwise the pivot columns of $A$ are independent and span $\operatorname{Col}A$: a basis. $\blacksquare$

> **⚠ Warning:** use the pivot columns **of $A$ itself** for the basis of $\operatorname{Col}A$. The columns of an echelon form $B$ are often **not** in $\operatorname{Col}A$. In Examples 7 and 8, every column of $B$ ends in $0$, so no combination of them can produce $\mathbf a_1 = (1,-2,2,3)$. Row reduction **preserves dependence relations but changes the column space.**

### Practice Problems (worked)

**1.** $A = \begin{bmatrix} 1 & -1 & 5\\ 2 & 0 & 7\\ -3 & -5 & -3\end{bmatrix}$, $\mathbf u = \begin{bmatrix} -7\\ 3\\ 2\end{bmatrix}$. *Is $\mathbf u$ in $\operatorname{Nul}A$? In $\operatorname{Col}A$?*

- **Nul:** just compute. $A\mathbf u = (-7-3+10,\ -14+0+14,\ 21-15-6) = (0,0,0)$, so **$\mathbf u \in \operatorname{Nul}A$.**
- **Col:** row reduce $[\,A\ \ \mathbf u\,]$:
$$
\begin{bmatrix} 1 & -1 & 5 & -7\\ 2 & 0 & 7 & 3\\ -3 & -5 & -3 & 2\end{bmatrix}
\sim
\begin{bmatrix} 1 & -1 & 5 & -7\\ 0 & 2 & -3 & 17\\ 0 & -8 & 12 & -19\end{bmatrix}
\sim
\begin{bmatrix} 1 & -1 & 5 & -7\\ 0 & 2 & -3 & 17\\ 0 & 0 & 0 & 49\end{bmatrix}.
$$
The last row says $0 = 49$, so $A\mathbf x = \mathbf u$ has no solution and **$\mathbf u \notin \operatorname{Col}A$.**

> **💡** Membership in $\operatorname{Nul}A$ is a single multiplication (implicit description). Membership in $\operatorname{Col}A$ takes a row reduction (explicit description).

**2.** $A = \begin{bmatrix} 0 & 1 & 0\\ 0 & 0 & 1\\ 0 & 0 & 0\end{bmatrix}$. *Find a vector in $\operatorname{Nul}A$ and a vector in $\operatorname{Col}A$.*

$A$ is already in reduced echelon form. $A\mathbf x = \mathbf 0$ says $x_2 = 0$, $x_3 = 0$, with $x_1$ free. So $\operatorname{Nul}A$ has basis $\mathbf v = (1,0,0)$. Any column of $A$ is in $\operatorname{Col}A$, e.g. column 2, which is again $(1,0,0)$. Here the same vector lies in **both**. For most $n\times n$ matrices, $\mathbf 0$ is the only vector in both $\operatorname{Nul}A$ and $\operatorname{Col}A$.

**3.** *If an $n\times n$ matrix $A$ is invertible, what are $\operatorname{Col}A$ and $\operatorname{Nul}A$?*

By the IMT the columns span $\mathbb R^n$, so $\operatorname{Col}A = \mathbb R^n$. Also $A\mathbf x = \mathbf 0$ has only the trivial solution, so $\operatorname{Nul}A = \{\mathbf 0\}$.

---

## §2.9 — Dimension and Rank

### Coordinate Systems

The main reason for choosing a **basis** rather than just a spanning set is that each vector in $H$ can then be written in **only one way** as a combination of the basis vectors.

> **📐 Uniqueness of coordinates.** If $\mathcal B = \{\mathbf b_1,\dots,\mathbf b_p\}$ is a basis for $H$, each $\mathbf x$ in $H$ has exactly one representation $\mathbf x = c_1\mathbf b_1 + \cdots + c_p\mathbf b_p$.

> **🔎 Proof.** A representation exists because $\mathcal B$ spans $H$. Suppose
> $$\mathbf x = c_1\mathbf b_1 + \cdots + c_p\mathbf b_p \quad\text{and}\quad \mathbf x = d_1\mathbf b_1 + \cdots + d_p\mathbf b_p. \tag{1}$$
> Subtracting,
> $$\mathbf 0 = \mathbf x - \mathbf x = (c_1 - d_1)\mathbf b_1 + \cdots + (c_p - d_p)\mathbf b_p. \tag{2}$$
> Since $\mathcal B$ is linearly independent, every weight in (2) is zero: $c_j = d_j$ for $1\le j\le p$. The two representations in (1) are the same. $\blacksquare$

> **📗 DEFINITION.** Suppose $\mathcal B = \{\mathbf b_1,\dots,\mathbf b_p\}$ is a basis for a subspace $H$. For each $\mathbf x$ in $H$, the **coordinates of $\mathbf x$ relative to the basis $\mathcal B$** are the weights $c_1,\dots,c_p$ such that $\mathbf x = c_1\mathbf b_1 + \cdots + c_p\mathbf b_p$, and the vector in $\mathbb R^p$
> $$[\mathbf x]_{\mathcal B} = \begin{bmatrix} c_1\\ \vdots\\ c_p\end{bmatrix}$$
> is called the **coordinate vector of $\mathbf x$ (relative to $\mathcal B$)**, or the **$\mathcal B$-coordinate vector of $\mathbf x$**.

> **⚠ Watch for:** the basis is an **ordered** list. The entries of $[\mathbf x]_{\mathcal B}$ depend on the order of the vectors in $\mathcal B$; swap $\mathbf b_1$ and $\mathbf b_2$ and the first two coordinates swap.

#### Example 1 — finding $[\mathbf x]_{\mathcal B}$ (worked)

$$
\mathbf v_1 = \begin{bmatrix}3\\6\\2\end{bmatrix},\quad
\mathbf v_2 = \begin{bmatrix}-1\\0\\1\end{bmatrix},\quad
\mathbf x = \begin{bmatrix}3\\12\\7\end{bmatrix},\quad
\mathcal B = \{\mathbf v_1, \mathbf v_2\}.
$$

$\mathcal B$ is a basis for $H = \operatorname{Span}\{\mathbf v_1, \mathbf v_2\}$, because $\mathbf v_1, \mathbf v_2$ are linearly independent (neither is a multiple of the other). *Is $\mathbf x$ in $H$, and if so, what is $[\mathbf x]_{\mathcal B}$?*

$\mathbf x \in H$ exactly when $c_1\mathbf v_1 + c_2\mathbf v_2 = \mathbf x$ is consistent, and the solution weights are the $\mathcal B$-coordinates:

$$
\begin{bmatrix} 3 & -1 & 3\\ 6 & 0 & 12\\ 2 & 1 & 7\end{bmatrix}
\sim
\begin{bmatrix} 1 & 0 & 2\\ 0 & 1 & 3\\ 0 & 0 & 0\end{bmatrix}
\quad\Longrightarrow\quad
c_1 = 2,\ c_2 = 3,\qquad
[\mathbf x]_{\mathcal B} = \begin{bmatrix}2\\3\end{bmatrix}.
$$

Check: $2(3,6,2) + 3(-1,0,1) = (3,12,7)$ ✓.

**Coordinates make $H$ look like $\mathbb R^p$.** The points of $H$ are in $\mathbb R^3$, but each is completely determined by its coordinate vector in $\mathbb R^2$. The basis lays a grid on the plane $H$: $\mathbf x$ is "2 steps along $\mathbf v_1$, 3 steps along $\mathbf v_2$." The correspondence $\mathbf x \mapsto [\mathbf x]_{\mathcal B}$ is a one-to-one correspondence (a bijection) between $H$ and $\mathbb R^2$ and **preserves linear combinations**. If $\mathbf x = \sum c_i\mathbf b_i$ and $\mathbf y = \sum d_i\mathbf b_i$, then $r\mathbf x + s\mathbf y = \sum (rc_i + sd_i)\mathbf b_i$, so by uniqueness $[r\mathbf x + s\mathbf y]_{\mathcal B} = r[\mathbf x]_{\mathcal B} + s[\mathbf y]_{\mathcal B}$. Such a correspondence is an **isomorphism**, and $H$ is **isomorphic** to $\mathbb R^2$. In general, a basis of $p$ vectors makes $H$ look and act the same as $\mathbb R^p$, even though the vectors in $H$ may have more than $p$ entries (more in §4.4).

### The Dimension of a Subspace

The definition of dimension needs two facts: every nonzero subspace **has** a basis, and every basis of a given subspace has the **same number** of vectors.

> **📐 Lemma (too many vectors).** If a subspace $H$ has a basis of $p$ vectors, then any set of more than $p$ vectors in $H$ is linearly dependent.

> **🔎 Proof.** Let $\{\mathbf b_1,\dots,\mathbf b_p\}$ be a basis and $\mathbf u_1,\dots,\mathbf u_q$ be vectors in $H$ with $q > p$. Each $\mathbf u_j$ is a combination of the basis: $\mathbf u_j = B\mathbf c_j$ for some $\mathbf c_j$ in $\mathbb R^p$, where $B = [\,\mathbf b_1\ \cdots\ \mathbf b_p\,]$. Let $C = [\,\mathbf c_1\ \cdots\ \mathbf c_q\,]$, a $p\times q$ matrix. Then
> $$U = [\,\mathbf u_1\ \cdots\ \mathbf u_q\,] = BC.$$
> $C$ has more columns than rows, so $C\mathbf x = \mathbf 0$ has a free variable and a nontrivial solution $\mathbf x$ (Theorem 8, §1.7). Then $U\mathbf x = B(C\mathbf x) = B\mathbf 0 = \mathbf 0$ with $\mathbf x\ne\mathbf 0$, a nontrivial dependence relation among $\mathbf u_1,\dots,\mathbf u_q$. $\blacksquare$

> **📐 Corollary (all bases have the same size).** If $H$ has a basis of $p$ vectors, every basis of $H$ has exactly $p$ vectors.

> **🔎 Proof.** Let $\mathcal C$ be another basis, with $q$ vectors. $\mathcal C$ is independent, so by the Lemma $q \le p$. Swapping the roles of the two bases, $p \le q$. So $q = p$. $\blacksquare$

> **📐 Lemma (bases exist).** Every nonzero subspace $H$ of $\mathbb R^n$ has a basis, with at most $n$ vectors.

> **🔎 Proof.** Build an independent set one vector at a time. Since $H \ne \{\mathbf 0\}$, pick a nonzero $\mathbf u_1$ in $H$; $\{\mathbf u_1\}$ is independent. Suppose independent $\mathbf u_1,\dots,\mathbf u_k$ in $H$ have been chosen. If they span $H$, they form a basis; stop. If not, pick $\mathbf u_{k+1}$ in $H$ outside $\operatorname{Span}\{\mathbf u_1,\dots,\mathbf u_k\}$. The enlarged set is still independent: in a relation $c_1\mathbf u_1 + \cdots + c_k\mathbf u_k + c_{k+1}\mathbf u_{k+1} = \mathbf 0$, if $c_{k+1}\ne0$ we could solve for $\mathbf u_{k+1}$ as a combination of the others, which is impossible; so $c_{k+1}=0$, and then all the other $c_i = 0$ by independence. Any set of more than $n$ vectors in $\mathbb R^n$ is dependent (Theorem 8, §1.7), so the process stops after at most $n$ steps, with a basis. $\blacksquare$

> **📗 DEFINITION.** The **dimension** of a nonzero subspace $H$, denoted $\dim H$, is the number of vectors in any basis for $H$. The dimension of the zero subspace $\{\mathbf 0\}$ is defined to be zero.

The zero subspace has **no** basis, because the zero vector by itself forms a linearly dependent set.

- $\mathbb R^n$ has dimension $n$: the standard basis has $n$ vectors, so by the Corollary every basis does.
- A **plane through $\mathbf 0$** in $\mathbb R^3$ is two-dimensional, and a **line through $\mathbf 0$** is one-dimensional.

#### Example 2 — $\dim\operatorname{Nul}A$ = number of free variables

In §2.8 Example 6, $\operatorname{Nul}A$ had the basis $\{\mathbf u, \mathbf v, \mathbf w\}$, so $\dim\operatorname{Nul}A = 3$. Each basis vector came from one free variable in $A\mathbf x = \mathbf 0$, and the construction always produces a basis this way. So:

$$\boxed{\ \dim\operatorname{Nul}A = \text{number of free variables in } A\mathbf x = \mathbf 0\ }$$

(If there are no free variables, $\operatorname{Nul}A = \{\mathbf 0\}$ and the dimension is $0$; the formula still holds.)

> **📗 DEFINITION.** The **rank** of a matrix $A$, denoted $\operatorname{rank}A$, is the dimension of the column space of $A$.

By Theorem 13, the pivot columns of $A$ form a basis for $\operatorname{Col}A$, so **$\operatorname{rank}A$ is the number of pivot columns of $A$.**

#### Example 3 — computing a rank (worked)

$$
A = \begin{bmatrix} 2 & 5 & -3 & -4 & 8\\ 4 & 7 & -4 & -3 & 9\\ 6 & 9 & -5 & 2 & 4\\ 0 & -9 & 6 & 5 & -6\end{bmatrix}
\sim
\begin{bmatrix} 2 & 5 & -3 & -4 & 8\\ 0 & -3 & 2 & 5 & -7\\ 0 & -6 & 4 & 14 & -20\\ 0 & -9 & 6 & 5 & -6\end{bmatrix}
\sim \cdots \sim
\begin{bmatrix} 2 & 5 & -3 & -4 & 8\\ 0 & -3 & 2 & 5 & -7\\ 0 & 0 & 0 & 4 & -6\\ 0 & 0 & 0 & 0 & 0\end{bmatrix}.
$$

Pivot columns are 1, 2, and 4, so $\boxed{\operatorname{rank}A = 3}$.

The two non-pivot columns (3 and 5) give two free variables in $A\mathbf x = \mathbf 0$, so $\dim\operatorname{Nul}A = 2$. Note $3 + 2 = 5$, the number of columns. That is no accident:

> **📐 THEOREM 14 — The Rank Theorem.** If a matrix $A$ has $n$ columns, then $\operatorname{rank}A + \dim\operatorname{Nul}A = n$.

> **🔎 Proof.** Every column of $A$ is either a pivot column or a non-pivot column, so
> $$(\text{number of pivot columns}) + (\text{number of non-pivot columns}) = n.$$
> By Theorem 13, the first count is $\operatorname{rank}A$. The non-pivot columns correspond exactly to the free variables of $A\mathbf x = \mathbf 0$, so by Example 2 the second count is $\dim\operatorname{Nul}A$. $\blacksquare$

> **💡 Why this matters:** the $n$ columns (the $n$ unknowns) split between two jobs. Each pivot column adds one dimension to the set of reachable $\mathbf b$'s ($\operatorname{Col}A$). Each free column adds one dimension to the solutions of $A\mathbf x = \mathbf 0$ ($\operatorname{Nul}A$). The Rank Theorem returns in §4.6 with more detail.

> **📐 THEOREM 15 — The Basis Theorem.** Let $H$ be a $p$-dimensional subspace of $\mathbb R^n$. Any linearly independent set of exactly $p$ elements in $H$ is automatically a basis for $H$. Also, any set of $p$ elements of $H$ that spans $H$ is automatically a basis for $H$.

This is plausible if you think of $H$ as isomorphic to $\mathbb R^p$: by the IMT, $p$ vectors in $\mathbb R^p$ are linearly independent if and only if they span $\mathbb R^p$.

> **🔎 Proof.** Assume $p \ge 1$. (For $p = 0$, $H = \{\mathbf 0\}$, which has no basis, so the theorem says nothing.)
>
> *Independent ⇒ basis.* Let $S = \{\mathbf u_1,\dots,\mathbf u_p\}$ be independent in $H$. If $S$ did not span $H$, pick $\mathbf v$ in $H$ outside $\operatorname{Span}S$. As in the "bases exist" Lemma, $S \cup \{\mathbf v\}$ is then independent: $p+1$ independent vectors in a subspace with a basis of $p$ vectors, contradicting the "too many vectors" Lemma. So $S$ spans $H$ and is a basis.
>
> *Spanning ⇒ basis.* Let $S = \{\mathbf u_1,\dots,\mathbf u_p\}$ span $H$. If $S$ were dependent, the trimming Lemma (§2.8) removes vectors one at a time, keeping a spanning set, until what remains is independent. That remainder spans $H \ne \{\mathbf 0\}$, so it is not empty, and it is a basis of $H$ with **fewer than $p$** vectors. This contradicts the Corollary that every basis of $H$ has $p$ vectors. So $S$ is independent, and a basis. $\blacksquare$

> **⚠ Watch for:** the Basis Theorem needs **both** hypotheses: the vectors lie in $H$ **and** their count equals $\dim H$. Three independent vectors in $\mathbb R^5$ are a basis for the 3-dimensional subspace they span, not for $\mathbb R^5$. The theorem returns in §4.5 and is used in Chapters 5 and 6.

### Rank and the Invertible Matrix Theorem

The subspace ideas give six more statements equivalent to invertibility. They are lettered to follow statements (a)–(l) of the IMT in §2.3.

> **📐 THEOREM — The Invertible Matrix Theorem (continued).** Let $A$ be an $n\times n$ matrix. Then the following statements are each equivalent to the statement that $A$ is an invertible matrix.
> - **m.** The columns of $A$ form a basis of $\mathbb R^n$.
> - **n.** $\operatorname{Col}A = \mathbb R^n$
> - **o.** $\dim\operatorname{Col}A = n$
> - **p.** $\operatorname{rank}A = n$
> - **q.** $\operatorname{Nul}A = \{\mathbf 0\}$
> - **r.** $\dim\operatorname{Nul}A = 0$

Recall from §2.3: **(d)** $A\mathbf x = \mathbf 0$ has only the trivial solution; **(e)** the columns of $A$ are linearly independent; **(g)** $A\mathbf x = \mathbf b$ has at least one solution for each $\mathbf b$ in $\mathbb R^n$; **(h)** the columns of $A$ span $\mathbb R^n$.

> **🔎 Proof.** **(m)** says exactly "(e) and (h)." If $A$ is invertible, (e) and (h) both hold, so (m) holds. If (m) holds, then (e) holds, so $A$ is invertible. Hence (m) is equivalent to invertibility.
>
> The other five statements are linked to the earlier ones by a chain of almost trivial implications:
> $$\text{(g)} \Rightarrow \text{(n)} \Rightarrow \text{(o)} \Rightarrow \text{(p)} \Rightarrow \text{(r)} \Rightarrow \text{(q)} \Rightarrow \text{(d)}.$$
> - **(g) ⇒ (n).** $\operatorname{Col}A$ is precisely the set of all $\mathbf b$ for which $A\mathbf x = \mathbf b$ is consistent. If that is every $\mathbf b$ in $\mathbb R^n$, then $\operatorname{Col}A = \mathbb R^n$.
> - **(n) ⇒ (o) ⇒ (p).** $\dim\mathbb R^n = n$, and $\operatorname{rank}A$ is by definition $\dim\operatorname{Col}A$.
> - **(p) ⇒ (r).** By the Rank Theorem, $\dim\operatorname{Nul}A = n - \operatorname{rank}A = n - n = 0$.
> - **(r) ⇒ (q).** The only subspace of dimension $0$ is $\{\mathbf 0\}$, since a nonzero subspace has a basis with at least one vector.
> - **(q) ⇒ (d).** $\operatorname{Nul}A = \{\mathbf 0\}$ says $A\mathbf x = \mathbf 0$ has only the trivial solution.
>
> Statements (d) and (g) are already known to be equivalent to invertibility. So if $A$ is invertible, (g) holds and the chain makes (n), (o), (p), (r), (q) all true. If any one of (n)–(r) holds, the chain carries it to (d), so $A$ is invertible. $\blacksquare$

> **📝 Numerical Note.** Many algorithms in this course are useful for understanding concepts and for simple hand computations, but are often unsuitable for large real-life problems. **Rank** is a good example. It seems easy to reduce to echelon form and count pivots. But unless arithmetic is exact and the entries are specified exactly, row operations can change the *apparent* rank. In
> $$\begin{bmatrix} 5 & 7\\ 5 & x\end{bmatrix},$$
> if $x$ is not stored exactly as $7$, the rank may come out $1$ or $2$, depending on whether the computer treats $x - 7$ as zero. In practice, the effective rank is often found from the **singular value decomposition** of $A$ (§7.4).

### Practice Problems (worked)

**1.** *Find the dimension of $H = \operatorname{Span}\{\mathbf v_1, \mathbf v_2, \mathbf v_3\}$ in $\mathbb R^3$ (first find a basis):*
$$\mathbf v_1 = \begin{bmatrix}2\\-8\\6\end{bmatrix},\quad \mathbf v_2 = \begin{bmatrix}3\\-7\\-1\end{bmatrix},\quad \mathbf v_3 = \begin{bmatrix}-1\\6\\-7\end{bmatrix}.$$

Make them the columns of $A$, so that $H = \operatorname{Col}A$, and find the pivot columns:
$$
A = \begin{bmatrix} 2 & 3 & -1\\ -8 & -7 & 6\\ 6 & -1 & -7\end{bmatrix}
\sim
\begin{bmatrix} 2 & 3 & -1\\ 0 & 5 & 2\\ 0 & -10 & -4\end{bmatrix}
\sim
\begin{bmatrix} 2 & 3 & -1\\ 0 & 5 & 2\\ 0 & 0 & 0\end{bmatrix}.
$$
The first two columns are pivot columns, so $\{\mathbf v_1, \mathbf v_2\}$ is a basis for $H$ and $\boxed{\dim H = 2}$. $H$ is a plane through the origin.

**2.** *Basis $\mathcal B = \left\{\begin{bmatrix}1\\.2\end{bmatrix}, \begin{bmatrix}.2\\1\end{bmatrix}\right\}$ for $\mathbb R^2$. If $[\mathbf x]_{\mathcal B} = \begin{bmatrix}3\\2\end{bmatrix}$, what is $\mathbf x$?*

The coordinates are the weights:
$$\mathbf x = 3\mathbf b_1 + 2\mathbf b_2 = 3\begin{bmatrix}1\\.2\end{bmatrix} + 2\begin{bmatrix}.2\\1\end{bmatrix} = \begin{bmatrix}3.4\\2.6\end{bmatrix}.$$
On the grid that $\mathcal B$ lays on $\mathbb R^2$, $\mathbf x$ is 3 units in the $\mathbf b_1$-direction and 2 units in the $\mathbf b_2$-direction.

> **⚠ Watch for:** going *to* coordinates ($\mathbf x \to [\mathbf x]_{\mathcal B}$) needs a row reduction, as in Example 1. Going *back* ($[\mathbf x]_{\mathcal B} \to \mathbf x$) is a single linear combination.

**3.** *Could $\mathbb R^3$ contain a four-dimensional subspace?*

No. A four-dimensional subspace would contain a basis of four linearly independent vectors, and any independent set in $\mathbb R^3$ has at most three vectors. $\mathbb R^3$ itself is its only three-dimensional subspace (Basis Theorem: three independent vectors in $\mathbb R^3$ span it). All other subspaces of $\mathbb R^3$ have dimension 2, 1, or 0.

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

The proof takes four steps, by induction on $n$ from the definition; later steps use earlier ones. All four claims are trivial for $1\times1$ matrices, and Steps 1 and 3 are checked directly for $n=2$. Throughout, **$M$ denotes $A$ with two rows and two columns deleted**, specified in each step.

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

> **📝 Numerical Note.** By today's standards a $25\times25$ matrix is small. Yet a $25\times25$ determinant **cannot** be computed by cofactor expansion. In general, a cofactor expansion takes more than $n!$ multiplications. (An $n\times n$ expansion multiplies $n$ entries by $n$ cofactors, each an $(n-1)\times(n-1)$ expansion. If $m_n$ counts the multiplications, then $m_2 = 2$ and $m_n = n(m_{n-1}+1) > n\,m_{n-1}$, so $m_n > n!$ for $n\ge3$; in fact $m_n \approx (e-1)\,n!$.) And $25! \approx 1.5\times10^{25}$, so $m_{25}\approx 2.7\times10^{25}$. At one trillion multiplications per second, that is more than 500,000 years (about 850,000). Faster methods come in §3.2.

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
