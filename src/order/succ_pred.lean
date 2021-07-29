/-
Copyright (c) 2021 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import order.bounded_lattice
import order.galois_connection

/-!
# Successor and predecessor

## Typeclasses

* `succ_order`: Order equipped with a sensible successor function.
* `add_succ_order`: Syntax-agreement typeclass stating that the `succ` of a `succ_order`
  coincides with `λ a, a + 1`.
* `pred_order`: Order equipped with a sensible predecessor function.
* `add_pred_order`: Syntax-agreement typeclass stating that the `pred` of a `pred_order`
  coincides with `λ a, a _ 1`.

## Implementation notes

Maximal elements don't have a sensible successor. Thus the naïve typeclass
```lean
class naive_succ_order (α : Type*) [preorder α] :=
(succ : α → α)
(succ_le_iff_lt : ∀ {a b}, a < b ↔ succ a ≤ b)
(lt_succ_iff_le : ∀ {a b}, a < succ b ↔ a ≤ b)
```
can't apply to an `order_top` because plugging in `a = b = ⊤` into either of `succ_le_iff_lt` and
`lt_succ_iff_le` yields `⊤ < ⊤`.
The solution taken here is to remove the implications `≤ → <` and instead require that `a < succ a`
for all non maximal elements (enforced by the combination of `le_succ` and the contrapositive of
`maximal_of_succ_le`).
The stricter condition of every element having a sensible successor can be obtained through the
combination of `succ_order α` and `no_top_order α`.

The previous discussion also applies to `preorder`s with a maximal element.
-/

/-! ### Successor order -/

/-- Order equipped with a sensible successor function. -/
@[ext] class succ_order (α : Type*) [preorder α] :=
(succ : α → α)
(le_succ : ∀ a, a ≤ succ a)
(maximal_of_succ_le : ∀ ⦃a⦄, succ a ≤ a → ∀ ⦃b⦄, ¬a < b)
(succ_le_of_lt : ∀ {a b}, a < b → succ a ≤ b)
(le_of_lt_succ : ∀ {a b}, a < succ b → a ≤ b)

open function succ_order

variables {α : Type*}

/-- A constructor for `succ_order α` usable when `α` has no maximal element. -/
def succ_order_of_lt_iff_succ_le [preorder α] (succ : α → α)
  (hlt_iff_succ_le : ∀ {a b}, a < b ↔ succ a ≤ b)
  (hle_of_lt_succ : ∀ {a b}, a < succ b → a ≤ b) :
  succ_order α :=
{ succ := succ,
  le_succ := λ a, (hlt_iff_succ_le.2 le_rfl).le,
  maximal_of_succ_le := λ a ha, (lt_irrefl a (hlt_iff_succ_le.2 ha)).elim,
  succ_le_of_lt := λ a b, hlt_iff_succ_le.1,
  le_of_lt_succ := λ a b, hle_of_lt_succ }

section preorder
variables [preorder α] [succ_order α]

@[simp] lemma succ_mono {a b : α} (h : a ≤ b) :
  succ a ≤ succ b :=
begin
  by_cases ha : ∀ ⦃c⦄, ¬a < c,
  { have hba : succ b ≤ a,
    { by_contra H,
      exact ha ((h.trans (le_succ b)).lt_of_not_le H) },
    by_contra H,
    exact ha ((h.trans (le_succ b)).trans_lt ((hba.trans (le_succ a)).lt_of_not_le H)) },
  push_neg at ha,
  obtain ⟨c, hc⟩ := ha,
  exact succ_le_of_lt ((h.trans (le_succ b)).lt_of_not_le $ λ hba,
    maximal_of_succ_le (hba.trans h) (((le_succ b).trans hba).trans_lt hc)),
end

section no_top_order
variables [no_top_order α]

lemma lt_succ (a : α) :
  a < succ a :=
(le_succ a).lt_of_not_le (λ h, not_exists.2 (maximal_of_succ_le h) (no_top a))

lemma lt_succ_iff_le {a b : α} :
  a < succ b ↔ a ≤ b :=
⟨le_of_lt_succ, λ h, h.trans_lt $ lt_succ b⟩

lemma lt_iff_succ_le {a b : α} :
  a < b ↔ succ a ≤ b :=
⟨succ_le_of_lt, (lt_succ a).trans_le⟩

@[simp] lemma succ_le_succ_iff {a b : α} :
  succ a ≤ succ b ↔ a ≤ b :=
⟨λ h, le_of_lt_succ $ (lt_succ a).trans_le h, λ h, succ_le_of_lt $ h.trans_lt $ lt_succ b⟩

@[simp] lemma succ_lt_succ_iff {a b : α} :
  succ a < succ b ↔ a < b :=
by simp_rw [lt_iff_le_not_le, succ_le_succ_iff]

end no_top_order

end preorder

section partial_order
variables [partial_order α]

instance : subsingleton (succ_order α) :=
begin
  refine subsingleton.intro (λ h₀ h₁, _),
  ext a,
  by_cases ha : @succ _ _ h₀ a ≤ a,
  { refine (ha.trans (@le_succ _ _ h₁ a)).antisymm _,
    by_contra H,
    exact @maximal_of_succ_le _ _ h₀ _ ha _
      ((@le_succ _ _ h₁ a).lt_of_not_le $ λ h, H $ h.trans $ @le_succ _ _ h₀ a) },
  exact (@succ_le_of_lt _ _ h₀ _ _ $ (@le_succ _ _ h₁ a).lt_of_not_le $ λ h,
    @maximal_of_succ_le _ _ h₁ _ h _ $ (@le_succ _ _ h₀ a).lt_of_not_le ha).antisymm
    (@succ_le_of_lt _ _ h₁ _ _ $ (@le_succ _ _ h₀ a).lt_of_not_le ha),
end

variables [succ_order α]

lemma le_le_succ_iff {a b : α} : a ≤ b ∧ b ≤ succ a ↔ b = a ∨ b = succ a :=
begin
  split,
  { rintro h,
    rw or_iff_not_imp_left,
    exact λ hba, h.2.antisymm (succ_le_of_lt $ h.1.lt_of_ne $ ne.symm hba) },
  rintro (rfl | rfl),
  { exact ⟨le_rfl, le_succ b⟩ },
  { exact ⟨le_succ a, le_rfl⟩ }
end

section no_top_order
variables [no_top_order α]

lemma succ_injective :
  injective (succ : α → α) :=
begin
  rintro a b,
  simp_rw [eq_iff_le_not_lt, succ_le_succ_iff, succ_lt_succ_iff],
  exact id,
end

lemma succ_eq_succ_iff {a b : α} :
  succ a = succ b ↔ a = b :=
succ_injective.eq_iff

lemma succ_ne_succ_iff {a b : α} :
  succ a ≠ succ b ↔ a ≠ b :=
succ_injective.ne_iff

end no_top_order

end partial_order

section order_top
variables [order_top α] [succ_order α]

@[simp] lemma succ_top :
  succ (⊤ : α) = ⊤ :=
le_top.antisymm (le_succ _)

@[simp] lemma succ_le_iff_eq_top {a : α} :
  succ a ≤ a ↔ a = ⊤ :=
⟨λ h, eq_top_of_maximal (maximal_of_succ_le h), λ h, by rw [h, succ_top]⟩

@[simp] lemma lt_succ_iff_ne_top {a : α} : a < succ a ↔ a ≠ ⊤ :=
begin
  simp only [lt_iff_le_not_le, true_and, le_succ a],
  exact not_iff_not.2 succ_le_iff_eq_top,
end

end order_top

section order_bot

lemma bot_lt_succ [order_bot α] [nontrivial α] [succ_order α] (a : α) :
  ⊥ < succ a :=
begin
  obtain ⟨b, hb⟩ := exists_ne (⊥ : α),
  refine bot_lt_iff_ne_bot.2 (λ h, _),
  have := eq_bot_iff.2 ((le_succ a).trans h.le),
  rw this at h,
  exact maximal_of_succ_le h.le (bot_lt_iff_ne_bot.2 hb),
end

end order_bot

section linear_order
variables [linear_order α] [succ_order α]

@[simp] lemma max_succ_succ {a b : α} :
  max (succ a) (succ b) = succ (max a b) :=
begin
  obtain h | h := le_total a b,
  { rw [max_eq_right h, max_eq_right (succ_mono h)] },
  { rw [max_eq_left h, max_eq_left (succ_mono h)] }
end

@[simp] lemma min_succ_succ {a b : α} :
  min (succ a) (succ b) = succ (min a b) :=
begin
  obtain h | h := le_total a b,
  { rw [min_eq_left h, min_eq_left (succ_mono h)] },
  { rw [min_eq_right h, min_eq_right (succ_mono h)] }
end

end linear_order

section complete_lattice
variables [complete_lattice α] [succ_order α]

lemma succ_eq_infi (a : α) : succ a = ⨅ (b : α) (h : a < b), b :=
begin
  refine le_antisymm (le_infi (λ b, le_infi succ_le_of_lt)) _,
  obtain rfl | ha := eq_or_ne a ⊤,
  { rw succ_top,
    exact le_top },
  exact binfi_le _ (lt_succ_iff_ne_top.2 ha),
end

end complete_lattice

/-- Class stating that `∀ a b, a < b ↔ a + 1 ≤ b` and `∀ a b, a < b + 1 ↔ a ≤ b`. `succ_order` with
additive notation. -/
class add_succ_order (α : Type*) [preorder α] [has_add α] [has_one α] extends
  succ_order α :=
(succ_eq_add_one : ∀ a, succ a = a + 1)

lemma lt_iff_add_one_le [preorder α] [no_top_order α] [has_add α] [has_one α]
  [add_succ_order α] {a b : α} :
  a < b ↔ a + 1 ≤ b :=
by { rw ←add_succ_order.succ_eq_add_one, exact lt_iff_succ_le }

lemma lt_add_one_iff_le [preorder α] [no_top_order α] [has_add α] [has_one α]
  [add_succ_order α] {a b : α} :
  a < b + 1 ↔ a ≤ b :=
by { rw ←add_succ_order.succ_eq_add_one, exact lt_succ_iff_le }

/-! ### Predecessor order -/

/-- Order equipped with a sensible predecessor function. -/
@[ext] class pred_order (α : Type*) [preorder α] :=
(pred : α → α)
(pred_le : ∀ a, pred a ≤ a)
(minimal_of_le_pred : ∀ ⦃a⦄, a ≤ pred a → ∀ ⦃b⦄, ¬b < a)
(le_pred_of_lt : ∀ {a b}, a < b → a ≤ pred b)
(le_of_pred_lt : ∀ {a b}, pred a < b → a ≤ b)

open pred_order

/-! ### Successor-predecessor order -/
