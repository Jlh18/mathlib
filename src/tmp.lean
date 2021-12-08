import analysis.calculus.mean_value
import measure_theory.measure.haar_lebesgue


variables {E : Type*} [normed_group E] [normed_space ℝ E]
          {F : Type*} [normed_group F] [normed_space ℝ F]

open metric set asymptotics
open_locale pointwise topological_space

/-- Consider a map `f` with an invertible derivative `f'` at a point `x`. Then the preimage under
`f` of a small neighborhood `f x + r • s` of `f x` resembles the preimage of `r • s` under `f'`.
Here we prove that the rescaling of the latter by a fixed factor `t < 1` is contained in the former,
for small enough `r`. -/
lemma eventually_smul_preimage_fderiv_subset_preimage
  {f : E → F} {x : E} {f' : E ≃L[ℝ] F} (hf : has_fderiv_at f (f' : E →L[ℝ] F) x)
  {s : set F} (s_conv : convex ℝ s) (hs : s ∈ 𝓝 (0 : F)) (h's : bounded s)
  {t : ℝ} (ht : t ∈ Ico (0 : ℝ) 1) :
  ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), {x} + r • t • f' ⁻¹' (s) ⊆ f ⁻¹' ({f x} + r • s) :=
begin
  obtain ⟨ε, εpos, hε⟩ : ∃ (ε : ℝ) (H : 0 < ε), t • s + closed_ball (0 : F) ε ⊆ s :=
    s_conv.exists_smul_add_closed_ball_subset hs ht,
  obtain ⟨R, Rpos, Rs⟩ : ∃ R, 0 < R ∧ f' ⁻¹' s ⊆ closed_ball (0 : E) R :=
    (f'.antilipschitz.bounded_preimage h's).subset_ball_lt _ _,
  obtain ⟨δ, δpos, hδ⟩ :
    ∃ (δ : ℝ) (H : 0 < δ), closed_ball 0 δ ⊆ {z : E | ∥f (x + z) - f x - f' z∥ ≤ (ε / R) * ∥z∥} :=
      nhds_basis_closed_ball.mem_iff.1
        ((has_fderiv_at_iff_is_o_nhds_zero.1 hf).def (div_pos εpos Rpos)),
  have : Ioc (0 : ℝ) (δ / R) ∈ 𝓝[Ioi (0 : ℝ)] 0,
  { apply Ioc_mem_nhds_within_Ioi,
    simp only [div_pos δpos Rpos, left_mem_Ico] },
  filter_upwards [this],
  rintros r ⟨rpos, rle⟩ y hy,
  obtain ⟨z, f'z, rfl⟩ : ∃ (z : E), f' z ∈ s ∧ x + r • t • z = y,
    by simpa only [mem_smul_set, image_add_left, exists_exists_and_eq_and, mem_preimage,
                   singleton_add, neg_add_eq_sub, eq_sub_iff_add_eq'] using hy, clear hy,
  have z_le : ∥z∥ ≤ R, by simpa only [mem_closed_ball, dist_zero_right] using Rs f'z,
  simp only [image_add_left, mem_preimage, singleton_add, neg_add_eq_sub],
  let u := f (x + (r * t) • z) - f x - f' ((r * t) • z),
  suffices H : (r * t) • f' z + u ∈ r • s,
  { convert H, simp only [add_sub_cancel'_right, smul_smul, u, continuous_linear_equiv.map_smul] },
  let v := r ⁻¹ • u,
  suffices H : t • f' z + v ∈ s,
  { have : (r * t) • f' z + u = r • (t • f' z + v),
      by simp only [smul_smul, mul_inv_cancel rpos.ne', smul_add, one_smul],
    rw this,
    exact smul_mem_smul_set H },
  suffices H : ∥u∥ ≤ ε * r,
  { apply hε,
    apply set.add_mem_add (smul_mem_smul_set f'z),
    simpa only [norm_smul, real.norm_eq_abs, abs_of_nonneg (inv_nonneg.mpr rpos.le),
      ← div_eq_inv_mul, div_le_iff rpos, mem_closed_ball, dist_zero_right] using H },
  have I₀ : ∥(r * t) • z∥ ≤ r * R, from calc
    ∥(r * t) • z∥ = r * t * ∥z∥ :
      by simp only [norm_smul, real.norm_eq_abs, abs_of_nonneg, mul_nonneg rpos.le ht.left]
    ... ≤ r * 1 * R : by apply_rules [mul_le_mul, ht.2.le, ht.1, norm_nonneg, mul_nonneg,
                                      zero_le_one, le_refl, rpos.le]
    ... = r * R : by rw [mul_one],
  have I : ∥(r * t) • z∥ ≤ δ, from calc
    ∥(r * t) • z∥ ≤ r * R : I₀
    ... ≤ (δ / R) * R : mul_le_mul_of_nonneg_right rle Rpos.le
    ... = δ : by field_simp [Rpos.ne'],
  calc ∥u∥ ≤ ε / R * ∥(r * t) • z∥ :
    by { apply hδ, simpa only [mem_closed_ball, dist_zero_right] using I }
  ... ≤ ε / R * (r * R) : mul_le_mul_of_nonneg_left I₀ (div_nonneg εpos.le Rpos.le)
  ... = ε * r : by { field_simp [Rpos.ne'], ring }
end

@[simp] lemma singleton_add_ball {E : Type*} [normed_group E] (x y : E) (r : ℝ) :
  {x} + ball y r = ball (x + y) r :=
by simp only [preimage_add_ball, image_add_left, singleton_add, sub_neg_eq_add, add_comm y x]

lemma singleton_add_ball_zero {E : Type*} [normed_group E] (x : E) (r : ℝ) :
  {x} + ball 0 r = ball x r :=
by simp


/-- If `u` is a neighborhood of `x`, then for small enough `r`, the closed ball
`closed_ball x r` is contained in `u`. -/
lemma eventually_closed_ball_subset
  {x : E} {u : set E} (hu : u ∈ 𝓝 x) :
  ∀ᶠ r in 𝓝 (0 : ℝ), closed_ball x r ⊆ u :=
begin
  obtain ⟨ε, εpos, hε⟩ : ∃ ε (hε : 0 < ε), closed_ball x ε ⊆ u :=
    nhds_basis_closed_ball.mem_iff.1 hu,
  have : Iic ε ∈ 𝓝 (0 : ℝ) := Iic_mem_nhds εpos,
  filter_upwards [this],
  assume r hr,
  exact subset.trans (closed_ball_subset_closed_ball hr) hε,
end

/-- If `s` is a bounded set, then for small enough `r`, the set `{x} + r • s` is contained in any
fixed neighborhood of `x`. -/
lemma eventually_singleton_add_smul_subset
  {x : E} {s : set E} (hs : bounded s) {u : set E} (hu : u ∈ 𝓝 x) :
  ∀ᶠ r in 𝓝 (0 : ℝ), {x} + r • s ⊆ u :=
begin
  obtain ⟨ε, εpos, hε⟩ : ∃ ε (hε : 0 < ε), closed_ball x ε ⊆ u :=
    nhds_basis_closed_ball.mem_iff.1 hu,
  obtain ⟨R, Rpos, hR⟩ : ∃ (R : ℝ), 0 < R ∧ s ⊆ closed_ball 0 R := hs.subset_ball_lt 0 0,
  have : metric.closed_ball (0 : ℝ) (ε / R) ∈ 𝓝 (0 : ℝ) :=
    closed_ball_mem_nhds _ (div_pos εpos Rpos),
  filter_upwards [this],
  assume r hr,
  simp only [image_add_left, singleton_add],
  assume y hy,
  obtain ⟨z, zs, hz⟩ : ∃ (z : E), z ∈ s ∧ r • z = -x + y, by simpa [mem_smul_set] using hy,
  have I : ∥r • z∥ ≤ ε := calc
    ∥r • z∥ = ∥r∥ * ∥z∥ : norm_smul _ _
    ... ≤ (ε / R) * R :
      mul_le_mul (mem_closed_ball_zero_iff.1 hr)
        (mem_closed_ball_zero_iff.1 (hR zs)) (norm_nonneg _) (div_pos εpos Rpos).le
    ... = ε : by field_simp [Rpos.ne'],
  have : y = x + r • z, by simp only [hz, add_neg_cancel_left],
  apply hε,
  simpa only [this, dist_eq_norm, add_sub_cancel', mem_closed_ball] using I,
end

lemma metric.bounded.smul {E : Type*} [normed_group E] {𝕜 : Type*} [normed_field 𝕜] [normed_space 𝕜 E]
  {s : set E} (hs : bounded s) (c : 𝕜) :
  bounded (c • s) :=
begin
  obtain ⟨R, Rpos, hR⟩ : ∃ (R : ℝ), 0 < R ∧ s ⊆ closed_ball 0 R := hs.subset_ball_lt 0 0,
  refine (bounded_iff_subset_ball 0).2 ⟨∥c∥ * R, _⟩,
  assume z hz,
  obtain ⟨y, ys, rfl⟩ : ∃ (y : E), y ∈ s ∧ c • y = z := mem_smul_set.1 hz,
  simp only [mem_closed_ball_zero_iff],
  calc ∥c • y∥ = ∥c∥ * ∥y∥ : norm_smul _ _
  ... ≤ ∥c∥ * R : mul_le_mul_of_nonneg_left (mem_closed_ball_zero_iff.1 (hR ys)) (norm_nonneg _)
end

lemma linear_map.image_smul_set {E : Type*} [add_comm_group E] {F : Type*} [add_comm_group F]
  {𝕜 : Type*} [field 𝕜] [module 𝕜 E] [module 𝕜 F] (f : E →ₗ[𝕜] F) (c : 𝕜) (s : set E) :
  f '' (c • s) = c • f '' s :=
begin
  apply subset.antisymm,
  { rintros x ⟨y, ⟨z, zs, rfl⟩, rfl⟩,
    exact ⟨f z, mem_image_of_mem _ zs, (f.map_smul _ _).symm ⟩ },
  { rintros x ⟨y, ⟨z, hz, rfl⟩, rfl⟩,
    exact (mem_image _ _ _).2 ⟨c • z, smul_mem_smul_set hz, f.map_smul _ _⟩ }
end

lemma linear_map.preimage_smul_set {E : Type*} [add_comm_group E] {F : Type*} [add_comm_group F]
  {𝕜 : Type*} [field 𝕜] [module 𝕜 E] [module 𝕜 F] (f : E →ₗ[𝕜] F) {c : 𝕜} (hc : c ≠ 0) (s : set F) :
  f ⁻¹' (c • s) = c • f ⁻¹' s :=
begin
  apply subset.antisymm,
  { rintros x ⟨y, ys, hy⟩,
    refine ⟨c⁻¹ • x, _, _⟩,
    { simp only [←hy, smul_smul, inv_mul_cancel hc, ys, ring_hom.id_apply, one_smul, mem_preimage,
        linear_map.map_smulₛₗ] },
    { simp only [smul_smul, mul_inv_cancel hc, one_smul] } },
  { rintros x ⟨y, hy, rfl⟩,
    refine ⟨f y, hy, by simp only [ring_hom.id_apply, linear_map.map_smulₛₗ]⟩ }
end

lemma linear_equiv.preimage_smul_set {E : Type*} [add_comm_group E] {F : Type*} [add_comm_group F]
  {𝕜 : Type*} [field 𝕜] [module 𝕜 E] [module 𝕜 F] (f : E ≃ₗ[𝕜] F) (c : 𝕜) (s : set F) :
  f ⁻¹' (c • s) = c • f ⁻¹' s :=
begin
  rcases eq_empty_or_nonempty s with rfl|hs,
  { simp only [preimage_empty, smul_set_empty] },
  rcases eq_or_ne c 0 with rfl|hc,
  { simp only [zero_smul_set hs, zero_smul_set (hs.preimage f.surjective)],
    ext x,
    simp only [linear_equiv.map_eq_zero_iff, mem_preimage, set.mem_zero] },
  { exact linear_map.preimage_smul_set (f : E →ₗ[𝕜] F) hc s }
end

lemma continuous_linear_equiv.preimage_smul_set {E : Type*} [normed_group E] {F : Type*} [normed_group F]
  {𝕜 : Type*} [normed_field 𝕜] [module 𝕜 E] [module 𝕜 F] (f : E ≃L[𝕜] F) (c : 𝕜) (s : set F) :
  f ⁻¹' (c • s) = c • f ⁻¹' s :=
linear_equiv.preimage_smul_set _ c s

lemma continuous_linear_map.image_smul_set {E : Type*} [normed_group E] {F : Type*} [normed_group F]
  {𝕜 : Type*} [normed_field 𝕜] [module 𝕜 E] [module 𝕜 F] (f : E →L[𝕜] F) (c : 𝕜) (s : set E) :
  f '' (c • s) = c • f '' s :=
linear_map.image_smul_set _ c s

lemma set_smul_mem_nhds_zero {E : Type*} [normed_group E] {𝕜 : Type*} [normed_field 𝕜] [normed_space 𝕜 E]
  {s : set E} (hs : s ∈ 𝓝 (0 : E)) {c : 𝕜} (hc : c ≠ 0) :
  c • s ∈ 𝓝 (0 : E) :=
begin
  obtain ⟨ε, εpos, hε⟩ : ∃ (ε : ℝ) (H : 0 < ε), ball 0 ε ⊆ s := metric.mem_nhds_iff.1 hs,
  have : c • ball (0 : E) ε ∈ 𝓝 (0 : E),
  { rw [smul_ball hc, smul_zero],
    exact ball_mem_nhds _ (mul_pos (by simpa using hc) εpos) },
  exact filter.mem_of_superset this ((set_smul_subset_set_smul_iff₀ hc).2 hε)
end

lemma set_smul_mem_nhds_zero_iff {E : Type*} [normed_group E] {𝕜 : Type*} [normed_field 𝕜] [normed_space 𝕜 E]
  (s : set E) {c : 𝕜} (hc : c ≠ 0) :
  c • s ∈ 𝓝 (0 : E) ↔ s ∈ 𝓝(0 : E) :=
begin
  refine ⟨λ h, _, λ h, set_smul_mem_nhds_zero h hc⟩,
  convert set_smul_mem_nhds_zero h (inv_ne_zero hc),
  rw [smul_smul, inv_mul_cancel hc, one_smul],
end


lemma eventually_image_ball_subset_image_ball_fderiv
  {f : E → F} {x : E} {f' : E →L[ℝ] F} (hf : has_fderiv_at f f' x) {ε : ℝ} (εpos : 0 < ε) :
  ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), f '' (ball x r) ⊆ ball (f x) (ε * r) + f' '' (ball 0 r) :=
begin
  obtain ⟨R, Rpos, hR⟩ : ∃ (R : ℝ) (H : R > 0),
    ball x R ⊆ {z : E | ∥f z - f x - f' (z - x)∥ ≤ ε * ∥z - x∥} :=
      metric.mem_nhds_iff.1 (is_o.def hf εpos),
  have : Ioo (0 : ℝ) R ∈ 𝓝[Ioi (0 : ℝ)] (0 : ℝ) := Ioo_mem_nhds_within_Ioi ⟨le_rfl, Rpos⟩,
  filter_upwards [this],
  rintros r hr y ⟨z, hz, rfl⟩,
  refine set.mem_add.2 ⟨f z - f' (z - x), f' (z - x), _, _, by abel⟩,
  { simp only [dist_eq_norm, mem_ball],
    calc ∥f z - f' (z - x) - f x∥
    = ∥f z - f x - f' (z - x)∥ : by { congr' 1, abel }
    ... ≤ ε * ∥z - x∥ : hR (ball_subset_ball hr.2.le hz)
    ... < ε * r : (mul_lt_mul_left εpos).2 (mem_ball_iff_norm.1 hz) },
  { apply mem_image_of_mem,
    simpa only [mem_ball_iff_norm, sub_zero] using hz }
end

lemma eventually_smul_image_ball_subset_image_ball_fderiv
  {f : E → F} {x : E} {f' : E →L[ℝ] F} (hf : has_fderiv_at f f' x) {ε : ℝ} (εpos : 0 < ε) :
  ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ),
    r⁻¹ • ({-f x} + f '' (ball x r)) ⊆ ball 0 ε + f' '' (ball 0 1) :=
begin
  filter_upwards [eventually_image_ball_subset_image_ball_fderiv hf εpos, self_mem_nhds_within],
  assume r hr rpos,
  replace rpos : 0 < r := rpos,
  have A : r⁻¹ ≠ 0, by simp only [rpos.ne', inv_eq_zero, ne.def, not_false_iff],
  have B : r⁻¹ * (ε * r) = ε, by field_simp [rpos.ne'],
  calc r⁻¹ • ({-f x} + f '' ball x r)
  ⊆ r⁻¹ • ({-f x} + (ball (f x) (ε * r) + f' '' (ball 0 r))) :
    smul_set_mono (add_subset_add subset.rfl hr)
  ... = ball 0 ε + f' '' ball 0 1 : begin
    rw [← add_assoc, singleton_add_ball, add_left_neg, smul_add_set, ← f'.image_smul_set,
      smul_ball A, smul_ball A],
    simp only [real.norm_eq_abs, smul_zero, abs_of_nonneg (inv_nonneg.2 rpos.le),
      inv_mul_cancel rpos.ne', B],
  end
end

/-- Consider a map `f` with an invertible derivative `f'` at a point `x`. Then the preimage under
`f` of a small neighborhood `f x + r • s` of `f x` resembles the preimage of `r • s` under `f'`.
Here we prove that the rescaling of the latter by a fixed factor `t < 1` is contained in the
intersection of the former with an arbitrary neighborhood of `x`, for small enough `r`. -/
lemma eventually_smul_preimage_fderiv_subset_inter_preimage
  {f : E → F} {x : E} {f' : E ≃L[ℝ] F} (hf : has_fderiv_at f (f' : E →L[ℝ] F) x)
  {s : set F} (s_conv : convex ℝ s) (hs : s ∈ 𝓝 (0 : F)) (h's : bounded s)
  {t : ℝ} (ht : t ∈ Ico (0 : ℝ) 1) {u : set E} (hu : u ∈ 𝓝 x) :
  ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), {x} + r • t • f' ⁻¹' (s) ⊆ u ∩ f ⁻¹' ({f x} + r • s) :=
begin
  have A : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), {x} + r • t • f' ⁻¹' (s) ⊆ f ⁻¹' ({f x} + r • s) :=
    eventually_smul_preimage_fderiv_subset_preimage hf s_conv hs h's ht,
  have B : ∀ᶠ r in 𝓝 (0 : ℝ), {x} + r • t • f' ⁻¹' (s) ⊆ u :=
    eventually_singleton_add_smul_subset ((f'.antilipschitz.bounded_preimage h's).smul _) hu,
  filter_upwards [A, nhds_within_le_nhds B],
  assume r hr h'r,
  exact subset_inter h'r hr
end

/-- Consider a map `f` with an invertible derivative `f'` at a point `x`. Then the preimage under
`f` of a small neighborhood `f x + r • s` of `f x` resembles the preimage of `r • s` under `f'`.
Here we prove that the rescaling of the former by a fixed factor `t < 1` is contained in the latter,
for small enough `r`, if `f` is a local homeomorphism. -/
lemma eventually_preimage_smul_subset_preimage_fderiv
  {f : local_homeomorph E F} {x : E} {f' : E ≃L[ℝ] F}
  (hx : x ∈ f.source) (hf : has_fderiv_at f (f' : E →L[ℝ] F) x)
  {s : set F} (s_conv : convex ℝ s) (hs : s ∈ 𝓝 (0 : F)) (h's : bounded s)
  {t : ℝ} (ht : 1 < t) :
  ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), f.source ∩ f ⁻¹' ({f x} + r • s) ⊆ {x} + r • t • f' ⁻¹' (s) :=
begin
  have htinv : t⁻¹ ∈ Ico (0 : ℝ) 1 := ⟨inv_nonneg.2 (zero_lt_one.trans ht).le, inv_lt_one ht⟩,
  have h'f : has_fderiv_at f.symm (f'.symm : F →L[ℝ] E) (f x) := f.has_fderiv_at_symm' hx hf,
  let s' := t • f' ⁻¹' s,
  have s'_conv : convex ℝ s', by { apply convex.smul, exact s_conv.linear_preimage f' },
  have hs' : s' ∈ 𝓝 (0 : E),
  { rw set_smul_mem_nhds_zero_iff _ (zero_lt_one.trans ht).ne',
    apply f'.continuous.continuous_at,
    simpa only [continuous_linear_equiv.map_zero] using hs },
  have h's' : bounded s' := (f'.antilipschitz.bounded_preimage h's).smul _,
  filter_upwards [eventually_smul_preimage_fderiv_subset_preimage h'f s'_conv hs' h's' htinv],
  assume r hr,
  simp only [f'.symm_preimage_preimage, s', hx, local_homeomorph.left_inv, mul_one, smul_smul,
    continuous_linear_equiv.preimage_smul_set, inv_mul_cancel (zero_lt_one.trans ht).ne'] at hr,
  rw [← smul_smul] at hr,
  calc f.source ∩ f ⁻¹' ({f x} + r • s)
    ⊆ f.source ∩ f ⁻¹' ((f.symm) ⁻¹' ({x} + r • t • ⇑f' ⁻¹' s)) :
      inter_subset_inter_right _ (preimage_mono hr)
    ... = f.source ∩ ({x} + r • t • ⇑f' ⁻¹' s) : f.source_inter_preimage_inv_preimage _
    ... ⊆ {x} + r • t • ⇑f' ⁻¹' s : inter_subset_right _ _
end


.

open filter measure_theory measure_theory.measure finite_dimensional

variables [measurable_space E] [finite_dimensional ℝ E] [borel_space E]
  (μ : measure E) [is_add_haar_measure μ]


lemma tendsto_mu_add_ball {s : set E} (hs : is_compact s) :
  tendsto (λ r, μ (closed_ball 0 r + s)) (𝓝 0) (𝓝 (μ s)) :=
sorry

lemma tendsto_add_haar_preimage_ball_div_add_haar_ball
  (f : local_homeomorph E E) (g : E →L[ℝ] E) (y : E) (y_mem : y ∈ f.target)
  (h : has_fderiv_at f.symm g y) :
  tendsto (λ r, μ (f.source ∩ f ⁻¹' (closed_ball y r)) / μ (closed_ball y r)) (𝓝[Ioi (0 : ℝ)] 0)
    (𝓝 (ennreal.of_real (abs (linear_map.det (g : E →ₗ[ℝ] E))))) :=
begin
  let d := ennreal.of_real (abs (linear_map.det (g : E →ₗ[ℝ] E))),
  let x := f.symm y,
  have x_mem : x ∈ f.source := f.map_target y_mem,
  have L1 : tendsto (λ ε, μ (closed_ball 0 ε + g '' (closed_ball 0 1)))
    (𝓝 0) (𝓝 (μ (g '' (closed_ball 0 1)))),
  { apply tendsto_mu_add_ball,
    exact (proper_space.is_compact_closed_ball _ _).image g.continuous },
  have L2 : tendsto (λ ε, μ (closed_ball 0 ε + g '' (closed_ball 0 1)))
    (𝓝 0) (𝓝 (d * μ (closed_ball 0 1))),
  { convert L1,

  }


end

#exit

  have B : ∀ m, d < m → ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ),
      μ (f.source ∩ f ⁻¹' (closed_ball y r)) / μ (closed_ball y r) < m,
  { assume m hm,
    have L : tendsto (λ (t : ℝ), ennreal.of_real (t ^ finrank ℝ E) * d) (𝓝[Ioi 1] 1)
      (𝓝 (ennreal.of_real (1 ^ finrank ℝ E) * d)),
    { apply ennreal.tendsto.mul_const _ (or.inr ennreal.of_real_ne_top),
      apply ennreal.tendsto_of_real (tendsto.pow _ _),
      exact nhds_within_le_nhds, },
    simp only [one_pow, one_mul, ennreal.of_real_one] at L,
    obtain ⟨t, tlim, ht⟩ : ∃ (t : ℝ), ennreal.of_real (t ^ finrank ℝ E) * d < m ∧
      1 < t := (((tendsto_order.1 L).2 _ hm).and self_mem_nhds_within).exists,
    have R1 : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ),
      f.source ∩ f ⁻¹' (closed_ball y r) = f.symm '' (closed_ball y r),
    { have : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), closed_ball y r ⊆ f.target,
      { apply nhds_within_le_nhds,
        exact eventually_closed_ball_subset (f.open_target.mem_nhds y_mem) },
      filter_upwards [this],
      assume r hr,
      have : f.is_image (f.source ∩ f ⁻¹' (closed_ball y r)) (closed_ball y r),
      { apply local_homeomorph.is_image.of_preimage_eq',
        simp only [inter_eq_right_iff_subset.mpr hr, ←inter_assoc, inter_self] },
      simpa only [inter_eq_right_iff_subset.mpr hr, ←inter_assoc, inter_self]
        using this.symm_image_eq.symm },
    filter_upwards [R1, self_mem_nhds_within],
    assume r hr1 rpos,
    change 0 < r at rpos,
    rw [hr1, ennreal.div_lt_iff (or.inl (add_haar_closed_ball_pos μ y rpos).ne')
          (or.inl (add_haar_closed_ball_lt_top μ y r).ne)],
  }
end

#exit
    have : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), μ (f.source ∩ f ⁻¹' (closed_ball y r)) ≤
      ennreal.of_real (r ^ finrank ℝ E) * ennreal.of_real (t ^ finrank ℝ E)
        * d * μ (closed_ball 0 1),
     { have : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), f.source ∩ f ⁻¹' ({f x} + r • closed_ball 0 1)
        ⊆ {x} + r • t • f' x ⁻¹' (closed_ball 0 1) :=
          eventually_preimage_smul_subset_preimage_fderiv x_mem (h x x_mem)
          (convex_closed_ball _ _) (closed_ball_mem_nhds _ zero_lt_one) bounded_closed_ball ht,
      filter_upwards [this, self_mem_nhds_within],
      assume r hr r_pos,
      replace r_pos : 0 < r := r_pos,
      calc
      μ (f.source ∩ f ⁻¹' (closed_ball y r))
      = μ (f.source ∩ f ⁻¹' ({f x} + r • closed_ball 0 1)) :
        by simp only [y_mem, smul_closed_ball, zero_le_one, real.norm_eq_abs, abs_of_nonneg r_pos.le,
          mul_one, preimage_add_closed_ball, image_add_left, local_homeomorph.right_inv, zero_add,
          singleton_add, smul_zero, sub_neg_eq_add]
      ... ≤ μ ({x} + r • t • ⇑(f' x) ⁻¹' closed_ball 0 1) : measure_mono hr
      ... = ennreal.of_real (r ^ finrank ℝ E) * ennreal.of_real (t ^ finrank ℝ E) * d
        * μ (closed_ball 0 1) : begin
          simp only [abs_of_nonneg, r_pos.le, (zero_lt_one.trans ht).le, mul_assoc, add_haar_smul,
            image_add_left, pow_nonneg, add_haar_preimage_add, singleton_add,
            haar_preimage_continuous_linear_equiv, coe_coe],
          refl,
        end },
    filter_upwards [this, self_mem_nhds_within],
    assume r hr rpos,
    replace rpos : 0 < r := rpos,
    apply lt_of_le_of_lt (ennreal.div_le_of_le_mul _) tlim,
    rw [add_haar_closed_ball' μ _ rpos.le],
    convert hr using 1,
    ring },
end

#exit


lemma tendsto_add_haar_preimage_ball_div_add_haar_ball
  (f : local_homeomorph E E) (f' : E → (E ≃L[ℝ] E))
  (h : ∀ x ∈ f.source, has_fderiv_at f (f' x : E →L[ℝ] E) x)
  (y : E) (y_mem : y ∈ f.target) :
  tendsto (λ r, μ (f.source ∩ f ⁻¹' (closed_ball y r)) / μ (closed_ball y r)) (𝓝[Ioi (0 : ℝ)] 0)
    (𝓝 (ennreal.of_real (abs (linear_map.det ((f' (f.symm y)).symm : E →ₗ[ℝ] E))))) :=
begin
  let d := ennreal.of_real (abs (linear_map.det ((f' (f.symm y)).symm : E →ₗ[ℝ] E))),
  let x := f.symm y,
  have x_mem : x ∈ f.source := f.map_target y_mem,
  have A : ∀ l, l < d → ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ),
      l < μ (f.source ∩ f ⁻¹' (closed_ball y r)) / μ (closed_ball y r),
  { assume l hl,
    have L : tendsto (λ (t : ℝ), ennreal.of_real (t ^ finrank ℝ E) * d) (𝓝[Ico 0 1] 1)
      (𝓝 (ennreal.of_real (1 ^ finrank ℝ E) * d)),
    { apply ennreal.tendsto.mul_const _ (or.inr ennreal.of_real_ne_top),
      apply ennreal.tendsto_of_real (tendsto.pow _ _),
      exact nhds_within_le_nhds, },
    simp only [one_pow, one_mul, ennreal.of_real_one] at L,
    haveI : (𝓝[Ico (0 : ℝ) 1] 1).ne_bot := right_nhds_within_Ico_ne_bot zero_lt_one,
    obtain ⟨t, tlim, ht⟩ : ∃ (t : ℝ), l < ennreal.of_real (t ^ finrank ℝ E) * d ∧
      t ∈ Ico (0 : ℝ) 1 := (((tendsto_order.1 L).1 _ hl).and self_mem_nhds_within).exists,
    have : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ),
      ennreal.of_real (r ^ finrank ℝ E) * ennreal.of_real (t ^ finrank ℝ E) * d * μ (closed_ball 0 1)
        ≤ μ (f.source ∩ f ⁻¹' (closed_ball y r)),
    { have : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), {x} + r • t • f' x ⁻¹' (closed_ball 0 1)
        ⊆ f.source ∩ f ⁻¹' ({f x} + r • closed_ball 0 1) :=
          eventually_smul_preimage_fderiv_subset_inter_preimage (h x x_mem)
            (convex_closed_ball _ _) (closed_ball_mem_nhds _ zero_lt_one) bounded_closed_ball ht
            (f.open_source.mem_nhds x_mem),
      filter_upwards [this, self_mem_nhds_within],
      assume r hr r_pos,
      replace r_pos : 0 < r := r_pos,
      calc
      ennreal.of_real (r ^ finrank ℝ E) * ennreal.of_real (t ^ finrank ℝ E) * d
        * μ (closed_ball 0 1)
      = μ ({x} + r • t • ⇑(f' x) ⁻¹' closed_ball 0 1) :
        by simp only [abs_of_nonneg, r_pos.le, ht.left, add_haar_smul, image_add_left, pow_nonneg,
          add_haar_preimage_add, singleton_add, mul_assoc, haar_preimage_continuous_linear_equiv]
      ... ≤ μ (f.source ∩ f ⁻¹' ({f x} + r • closed_ball 0 1)) : measure_mono hr
      ... = μ (f.source ∩ f ⁻¹' closed_ball y r) :
        by simp only [y_mem, smul_closed_ball, zero_le_one, real.norm_eq_abs, abs_of_nonneg r_pos.le,
          mul_one, preimage_add_closed_ball, image_add_left, local_homeomorph.right_inv, zero_add,
          singleton_add, smul_zero, sub_neg_eq_add] },
    filter_upwards [this, self_mem_nhds_within],
    assume r hr rpos,
    replace rpos : 0 < r := rpos,
    apply tlim.trans_le,
    rw [ennreal.le_div_iff_mul_le (or.inl (add_haar_closed_ball_pos μ _ rpos).ne')
      (or.inl (add_haar_closed_ball_lt_top μ _ _).ne), add_haar_closed_ball' μ _ rpos.le],
    convert hr using 1,
    ring },
  have B : ∀ m, d < m → ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ),
      μ (f.source ∩ f ⁻¹' (closed_ball y r)) / μ (closed_ball y r) < m,
  { assume m hm,
    have L : tendsto (λ (t : ℝ), ennreal.of_real (t ^ finrank ℝ E) * d) (𝓝[Ioi 1] 1)
      (𝓝 (ennreal.of_real (1 ^ finrank ℝ E) * d)),
    { apply ennreal.tendsto.mul_const _ (or.inr ennreal.of_real_ne_top),
      apply ennreal.tendsto_of_real (tendsto.pow _ _),
      exact nhds_within_le_nhds, },
    simp only [one_pow, one_mul, ennreal.of_real_one] at L,
    obtain ⟨t, tlim, ht⟩ : ∃ (t : ℝ), ennreal.of_real (t ^ finrank ℝ E) * d < m ∧
      1 < t := (((tendsto_order.1 L).2 _ hm).and self_mem_nhds_within).exists,
    have : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), μ (f.source ∩ f ⁻¹' (closed_ball y r)) ≤
      ennreal.of_real (r ^ finrank ℝ E) * ennreal.of_real (t ^ finrank ℝ E)
        * d * μ (closed_ball 0 1),
     { have : ∀ᶠ r in 𝓝[Ioi (0 : ℝ)] (0 : ℝ), f.source ∩ f ⁻¹' ({f x} + r • closed_ball 0 1)
        ⊆ {x} + r • t • f' x ⁻¹' (closed_ball 0 1) :=
          eventually_preimage_smul_subset_preimage_fderiv x_mem (h x x_mem)
          (convex_closed_ball _ _) (closed_ball_mem_nhds _ zero_lt_one) bounded_closed_ball ht,
      filter_upwards [this, self_mem_nhds_within],
      assume r hr r_pos,
      replace r_pos : 0 < r := r_pos,
      calc
      μ (f.source ∩ f ⁻¹' (closed_ball y r))
      = μ (f.source ∩ f ⁻¹' ({f x} + r • closed_ball 0 1)) :
        by simp only [y_mem, smul_closed_ball, zero_le_one, real.norm_eq_abs, abs_of_nonneg r_pos.le,
          mul_one, preimage_add_closed_ball, image_add_left, local_homeomorph.right_inv, zero_add,
          singleton_add, smul_zero, sub_neg_eq_add]
      ... ≤ μ ({x} + r • t • ⇑(f' x) ⁻¹' closed_ball 0 1) : measure_mono hr
      ... = ennreal.of_real (r ^ finrank ℝ E) * ennreal.of_real (t ^ finrank ℝ E) * d
        * μ (closed_ball 0 1) : begin
          simp only [abs_of_nonneg, r_pos.le, (zero_lt_one.trans ht).le, mul_assoc, add_haar_smul,
            image_add_left, pow_nonneg, add_haar_preimage_add, singleton_add,
            haar_preimage_continuous_linear_equiv, coe_coe],
          refl,
        end },
    filter_upwards [this, self_mem_nhds_within],
    assume r hr rpos,
    replace rpos : 0 < r := rpos,
    apply lt_of_le_of_lt (ennreal.div_le_of_le_mul _) tlim,
    rw [add_haar_closed_ball' μ _ rpos.le],
    convert hr using 1,
    ring },
  exact tendsto_order.2 ⟨A, B⟩,

end
