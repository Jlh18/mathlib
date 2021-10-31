/-
Copyright (c) 2021 Alex Zhao. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Alex Zhao
-/
import data.nat.modeq

/-!
# Chicken McNugget Theorem

In this file we prove the Chicken McNugget Theorem.

## Theorem Statement:
The Chicken McNugget Theorem states,
for two relatively prime integers larger than 1,
the largest integer not expressible as a sum of nonnegative multiples of these two
is m * n - m - n.

## Implementation Notes

This proof uses Bezout's greatest common divisor theorem
to create a construction for all integers greater than the maximal value
m * n - m - n. To show the maximal value doesn't work, it rewrites the equation into a multiple
of m equalling a multiple of n, then uses inequalities to show the multiples get too large.

## Tags

chicken mcnugget, frobenius coin
-/

open nat

/-- Auxiliary lemma for upper bound. -/
lemma chicken_mcnugget_upper_bound_aux (a b m n : ℕ) (ha : a ≠ 0) (hb : b ≠ 0)
  (cop : coprime m n) : a * m + b * n ≠ m * n :=
begin
  intro h,
obtain ⟨x, rfl⟩ := cop.symm.dvd_of_dvd_mul_right ((nat.dvd_add_iff_left (dvd_mul_left n b)).mpr
    ((congr_arg _ h).mpr (dvd_mul_left n m))),
  obtain ⟨y, rfl⟩ := cop.dvd_of_dvd_mul_right ((nat.dvd_add_iff_right (dvd_mul_left m (n * x))).mpr
      ((congr_arg _ h).mpr (dvd_mul_right m n))),
  rw [mul_comm n x, mul_comm m y, mul_assoc, mul_assoc, mul_comm n m, ←add_mul] at h,
  rw [mul_comm, mul_ne_zero_iff, ←one_le_iff_ne_zero] at ha hb,
  exact mul_ne_zero hb.2 ha.2 (eq_zero_of_mul_eq_self_left (ne_of_gt (add_le_add ha.1 hb.1)) h),
end

/-- No solution for the maximal value over the natural numbers. -/
lemma chicken_mcnugget_upper_bound (m n : ℕ) (cop : coprime m n) (hm : 1 < m) (hn : 1 < n) :
  ¬ ∃ (a b : ℕ), a * m + b * n = m * n - m - n :=
begin
  rintro ⟨a, b, h⟩,
  apply chicken_mcnugget_upper_bound_aux _ _ m n (add_one_ne_zero a) (add_one_ne_zero b) cop,
  rw [add_mul, add_mul, one_mul, one_mul, add_assoc, ←add_assoc m, add_comm m, add_assoc,
      ←add_assoc, h, nat.sub_sub, nat.sub_add_cancel (add_le_mul hm hn)],
end

lemma chicken_mcnugget_construction (m n : ℕ) (cop : coprime m n) (hm : 1 < m) (hn : 1 < n) :
  ∀ k, m * n - m - n < k → ∃ (a b : ℕ), a * m + b * n = k :=
begin
  intros k hk,
  let x := chinese_remainder cop 0 k,
  have key := modeq.le_of_lt_add x.2.2 (calc x.1 ≤ m * n - m : modeq.le_of_lt_add (x.2.1.trans
    (modeq_zero_iff_dvd.mpr (nat.dvd_sub' (dvd_mul_right m n) dvd_rfl)).symm) (lt_of_lt_of_le
    (chinese_remainder_lt_mul cop 0 k (pos_of_gt hm).ne' (pos_of_gt hn).ne') le_tsub_add)
  ... = m * n - m - n + n : (nat.sub_add_cancel (le_tsub_of_add_le_left (add_le_mul hm hn))).symm
  ... < k + n : add_lt_add_right hk n),
  obtain ⟨a, ha⟩ := modeq_zero_iff_dvd.mp x.2.1,
  obtain ⟨b, hb⟩ := (modeq_iff_dvd' key).mp x.2.2,
  exact ⟨a, b, by rw [mul_comm, ←ha, mul_comm, ←hb, nat.add_sub_of_le key]⟩,
end

/-- This theorem combines both sublemmas in a single claim. -/
theorem chicken_mcnugget (m n : ℕ) (hm : 1 < m) (hn: 1 < n) (cop: coprime m n) :
  (¬ ∃ a b, a * m + b * n = m * n - m - n) ∧ ∀ k, k > m * n - m - n → ∃ a b, a * m + b * n = k :=
⟨chicken_mcnugget_upper_bound m n cop hm hn, chicken_mcnugget_construction m n cop hm hn⟩
