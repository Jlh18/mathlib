/-
Copyright (c) 2021 Kexing Ying. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kexing Ying
-/

import measure_theory.integral.set_integral

-- Probability should move to `measure_theory/integral`

noncomputable theory
open_locale classical measure_theory nnreal ennreal topological_space

namespace measure_theory

open set filter topological_space

section move

/-
### Egorov's theorem

If `f : ℕ → α → β` is a sequence of measurable functions where `β` is a separable metric space,
and `f` converges to `g : α → β` almost surely on a measurable set `s : set α` of finite measure,
then, for all `ε > 0`, there exists a subset `t ⊆ s` such that `μ t < ε` and `f` converges to
`g` uniformly on `A \ B`.

Useful:
-- `nnreal.has_sum_geometric` in `analysis.specific_limits`
-/

variables {α β ι : Type*} {m : measurable_space α}
  [metric_space β] [second_countable_topology β] [measurable_space β] [borel_space β]
  {μ : measure α}

def not_convergent_seq (f : ℕ → α → β) (g : α → β) (i j : ℕ) : set α :=
⋃ k (hk : j ≤ k), {x | (1 / (i + 1 : ℝ)) < dist (f k x) (g x)}

variables {f : ℕ → α → β} {g : α → β}

lemma mem_not_convergent_seq_iff {i j : ℕ} {x : α} : x ∈ not_convergent_seq f g i j ↔
  ∃ k (hk : j ≤ k), (1 / (i + 1 : ℝ)) < dist (f k x) (g x) :=
by { simp_rw [not_convergent_seq, mem_Union], refl }

lemma not_convergent_seq_measurable_set
  (hf : ∀ n, measurable[m] (f n)) (hg : measurable g)
  {i j : ℕ} : measurable_set (not_convergent_seq f g i j) :=
measurable_set.Union (λ k, measurable_set.Union_Prop $ λ hk,
  measurable_set_lt measurable_const $ (hf k).dist hg)

lemma not_convergent_seq_antitone {i : ℕ} :
  antitone (not_convergent_seq f g i) :=
λ j k hjk, bUnion_subset_bUnion (λ l hl, ⟨l, le_trans hjk hl, subset.refl _⟩)

lemma measure_inter_not_convergent_seq_eq_zero {s : set α} (hsm : measurable_set s)
  (hfg : ∀ᵐ x ∂μ, x ∈ s → tendsto (λ n, f n x) at_top (𝓝 (g x))) (i : ℕ) :
  μ (s ∩ ⋂ j, not_convergent_seq f g i j) = 0 :=
begin
  simp_rw [metric.tendsto_at_top, ae_iff] at hfg,
  rw [← nonpos_iff_eq_zero, ← hfg],
  refine measure_mono (λ x, _),
  simp only [mem_inter_eq, mem_Inter, ge_iff_le, mem_not_convergent_seq_iff],
  push_neg,
  rintro ⟨hmem, hx⟩,
  refine ⟨hmem, 1 / (i + 1 : ℝ), nat.one_div_pos_of_nat, λ N, _⟩,
  obtain ⟨n, hn₁, hn₂⟩ := hx N,
  exact ⟨n, hn₁, hn₂.le⟩
end

lemma measure_not_convergent_seq_tendsto_zero
  (hf : ∀ n, measurable[m] (f n)) (hg : measurable g)
  {s : set α} (hsm : measurable_set s) (hs : μ s < ∞)
  (hfg : ∀ᵐ x ∂μ, x ∈ s → tendsto (λ n, f n x) at_top (𝓝 (g x))) (i : ℕ) :
  tendsto (λ j, μ (s ∩ not_convergent_seq f g i j)) at_top (𝓝 0) :=
begin
  rw [← measure_inter_not_convergent_seq_eq_zero hsm hfg, inter_Inter],
  exact tendsto_measure_Inter (λ n, hsm.inter $ not_convergent_seq_measurable_set hf hg)
    (λ k l hkl, inter_subset_inter_right _ $ not_convergent_seq_antitone hkl)
    ⟨0, (lt_of_le_of_lt (measure_mono $ inter_subset_left _ _) hs).ne⟩
end

lemma exists_not_convergent_seq_lt {ε : ℝ} (hε : 0 < ε)
  (hf : ∀ n, measurable[m] (f n)) (hg : measurable g)
  {s : set α} (hsm : measurable_set s) (hs : μ s < ∞)
  (hfg : ∀ᵐ x ∂μ, x ∈ s → tendsto (λ n, f n x) at_top (𝓝 (g x))) (i : ℕ) :
  ∃ j : ℕ, μ (s ∩ not_convergent_seq f g i j) ≤ ennreal.of_real (ε * 2^(-(i : ℝ))) :=
begin
  obtain ⟨N, hN⟩ := (ennreal.tendsto_at_top ennreal.zero_ne_top).1
    (measure_not_convergent_seq_tendsto_zero hf hg hsm hs hfg i)
    (ennreal.of_real (ε * 2 ^ -(i : ℝ))) _,
  { rw zero_add at hN,
    exact ⟨N, (hN N le_rfl).2⟩ },
  { rw [gt_iff_lt, ennreal.of_real_pos],
    exact mul_pos hε (real.rpow_pos_of_pos (by norm_num) _) }
end

def not_convergent_seq_lt_index {ε : ℝ} (hε : 0 < ε)
  (hf : ∀ n, measurable[m] (f n)) (hg : measurable g)
  {s : set α} (hsm : measurable_set s) (hs : μ s < ∞)
  (hfg : ∀ᵐ x ∂μ, x ∈ s → tendsto (λ n, f n x) at_top (𝓝 (g x))) (i : ℕ) : ℕ :=
classical.some $ exists_not_convergent_seq_lt hε hf hg hsm hs hfg i

lemma not_convergent_seq_lt_index_spec {ε : ℝ} (hε : 0 < ε)
  (hf : ∀ n, measurable[m] (f n)) (hg : measurable g)
  {s : set α} (hsm : measurable_set s) (hs : μ s < ∞)
  (hfg : ∀ᵐ x ∂μ, x ∈ s → tendsto (λ n, f n x) at_top (𝓝 (g x))) (i : ℕ) :
  μ (s ∩ not_convergent_seq f g i (not_convergent_seq_lt_index hε hf hg hsm hs hfg i)) ≤
  ennreal.of_real (ε * 2^(-(i : ℝ))) :=
classical.some_spec $ exists_not_convergent_seq_lt hε hf hg hsm hs hfg i

theorem egorov {f : ℕ → α → β} {g : α → β} {s : set α} (hsm : measurable_set s) (hs : μ s < ∞)
  (hfg : ∀ᵐ x ∂μ, x ∈ s → tendsto (λ n, f n x) at_top (𝓝 (g x))) {ε : ℝ} (hε : 0 < ε) :
  ∃ t ⊆ s, μ t < ennreal.of_real ε ∧ tendsto_uniformly_on f g at_top t :=
begin
  sorry
end

end move

variables {α β ι : Type*} [normed_group β]

-- **Change doc-strings**

/-- A family `I` of (L₁-)functions is known as uniformly integrable if for all `ε > 0`, there
exists some `δ > 0` such that for all `f ∈ I` and measurable sets `s` with measure less than `δ`,
we have `∫ x in s, ∥f x∥ < ε`.

This is the measure theory verison of uniform integrability. -/
def unif_integrable {m : measurable_space α} (μ : measure α) (f : ι → α → β) : Prop :=
∀ ε : ℝ≥0∞, ∃ δ : ℝ≥0∞, ∀ i s, measurable_set s → μ s < δ →
snorm (set.indicator s (f i)) 1 μ < ε

/-- In probability theory, a family of functions is uniformly integrable if it is uniformly
integrable in the measure theory sense and is uniformly bounded. -/
def uniform_integrable {m : measurable_space α} [measurable_space β]
  (μ : measure α) (f : ι → α → β) : Prop :=
(∀ i, measurable (f i)) ∧ unif_integrable μ f ∧
  ∃ C : ℝ≥0, ∀ i, snorm (f i) 1 μ < C

variables {m : measurable_space α} {μ : measure α} [measurable_space β] {f : ι → α → β}

lemma uniform_integrable.mem_ℒp_one (hf : uniform_integrable μ f) (i : ι) :
  mem_ℒp (f i) 1 μ :=
⟨(hf.1 i).ae_measurable, let ⟨_, _, hC⟩ := hf.2 in lt_trans (hC i) ennreal.coe_lt_top⟩

end measure_theory
