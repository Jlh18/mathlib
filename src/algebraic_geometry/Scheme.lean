/-
Copyright (c) 2020 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import algebraic_geometry.Spec

/-!
# The category of schemes

A scheme is a locally ringed space such that every point is contained in some open set
where there is an isomorphism of presheaves between the restriction to that open set,
and the structure sheaf of `Spec R`, for some commutative ring `R`.

A morphism of schemes is just a morphism of the underlying locally ringed spaces.

-/

noncomputable theory

open topological_space
open category_theory
open Top
open opposite

namespace algebraic_geometry

/--
We define `Scheme` as a `X : LocallyRingedSpace`,
along with a proof that every point has an open neighbourhood `U`
so that that the restriction of `X` to `U` is isomorphic,
as a locally ringed space, to `Spec.to_LocallyRingedSpace.obj (op R)`
for some `R : CommRing`.
-/
structure Scheme extends to_LocallyRingedSpace : LocallyRingedSpace :=
(local_affine : ∀ x : to_LocallyRingedSpace, ∃ (U : open_nhds x) (R : CommRing),
  nonempty (to_LocallyRingedSpace.restrict U.open_embedding ≅
    Spec.to_LocallyRingedSpace.obj (op R)))

namespace Scheme

/--
Schemes are a full subcategory of locally ringed spaces.
-/
instance : category Scheme :=
induced_category.category Scheme.to_LocallyRingedSpace

/-- The structure sheaf of a Scheme. -/
protected abbreviation sheaf (X : Scheme) := X.to_SheafedSpace.sheaf

/-- The forgetful functor from `Scheme` to `LocallyRingedSpace`. -/
@[simps, derive[full, faithful]]
def forget_to_LocallyRingedSpace : Scheme ⥤ LocallyRingedSpace :=
  induced_functor _

@[simp] lemma forget_to_LocallyRingedSpace_preimage {X Y : Scheme} (f : X ⟶ Y) :
  Scheme.forget_to_LocallyRingedSpace.preimage f = f := rfl

/-- The forgetful functor from `Scheme` to `Top`. -/
@[simps]
def forget_to_Top : Scheme ⥤ Top :=
  Scheme.forget_to_LocallyRingedSpace ⋙ LocallyRingedSpace.forget_to_Top

/--
The spectrum of a commutative ring, as a scheme.
-/
def Spec_obj (R : CommRing) : Scheme :=
{ local_affine := λ x,
  ⟨⟨⊤, trivial⟩, R, ⟨(Spec.to_LocallyRingedSpace.obj (op R)).restrict_top_iso⟩⟩,
  to_LocallyRingedSpace := Spec.LocallyRingedSpace_obj R }

@[simp] lemma Spec_obj_to_LocallyRingedSpace (R : CommRing) :
  (Spec_obj R).to_LocallyRingedSpace = Spec.LocallyRingedSpace_obj R := rfl

/--
The induced map of a ring homomorphism on the ring spectra, as a morphism of schemes.
-/
def Spec_map {R S : CommRing} (f : R ⟶ S) :
  Spec_obj S ⟶ Spec_obj R :=
(Spec.LocallyRingedSpace_map f : Spec.LocallyRingedSpace_obj S ⟶ Spec.LocallyRingedSpace_obj R)

@[simp] lemma Spec_map_id (R : CommRing) :
  Spec_map (𝟙 R) = 𝟙 (Spec_obj R) :=
Spec.LocallyRingedSpace_map_id R

lemma Spec_map_comp {R S T : CommRing} (f : R ⟶ S) (g : S ⟶ T) :
  Spec_map (f ≫ g) = Spec_map g ≫ Spec_map f :=
Spec.LocallyRingedSpace_map_comp f g

/--
The spectrum, as a contravariant functor from commutative rings to schemes.
-/
@[simps] def Spec : CommRingᵒᵖ ⥤ Scheme :=
{ obj := λ R, Spec_obj (unop R),
  map := λ R S f, Spec_map f.unop,
  map_id' := λ R, by rw [unop_id, Spec_map_id],
  map_comp' := λ R S T f g, by rw [unop_comp, Spec_map_comp] }

/--
The empty scheme, as `Spec 0`.
-/
def empty : Scheme :=
Spec_obj (CommRing.of punit)

instance : has_emptyc Scheme := ⟨empty⟩

instance : inhabited Scheme := ⟨∅⟩

/--
The global sections, notated Gamma.
-/
def Γ : Schemeᵒᵖ ⥤ CommRing :=
(induced_functor Scheme.to_LocallyRingedSpace).op ⋙ LocallyRingedSpace.Γ

lemma Γ_def : Γ = (induced_functor Scheme.to_LocallyRingedSpace).op ⋙ LocallyRingedSpace.Γ := rfl

@[simp] lemma Γ_obj (X : Schemeᵒᵖ) : Γ.obj X = (unop X).presheaf.obj (op ⊤) := rfl

lemma Γ_obj_op (X : Scheme) : Γ.obj (op X) = X.presheaf.obj (op ⊤) := rfl

@[simp] lemma Γ_map {X Y : Schemeᵒᵖ} (f : X ⟶ Y) :
  Γ.map f = f.unop.1.c.app (op ⊤) := rfl

lemma Γ_map_op {X Y : Scheme} (f : X ⟶ Y) :
  Γ.map f.op = f.1.c.app (op ⊤) := rfl

-- PROJECTS:
-- 1. Construct `Spec ≫ Γ ≅ functor.id _`.
-- 2. Adjunction between `Γ` and `Spec`.
--

end Scheme

end algebraic_geometry
