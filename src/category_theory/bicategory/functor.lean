/-
Copyright (c) 2022 Yuma Mizuno. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yuma Mizuno
-/
import category_theory.bicategory.basic

/-!
# Oplax functors

An oplax functor `F` between bicategories `B` and `C` consists of
* a function between objects `F.obj : B ⟶ C`,
* a family of functions between 1-morphisms `F.map : (a ⟶ b) → (obj a ⟶ obj b)`,
* a family of functions between 2-morphisms `F.map₂ : (f ⟶ g) → (map f ⟶ map g)`,
* a family of 2-morphisms `F.map_id a : F.map (𝟙 a) ⟶ 𝟙 (F.obj a)`,
* a family of 2-morphisms `F.map_comp f g : F.map (f ≫ g) ⟶ F.map f ≫ F.map g`, and
* certain consistency conditions on them.
-/

set_option old_structure_cmd true

namespace category_theory

open category bicategory
open_locale bicategory

universes w₁ w₂ w₃ v₁ v₂ v₃ u₁ u₂ u₃

section

/--
A prepseudofunctor between bicategories consists of functions between objects,
1-morphisms, and 2-morphisms. This structure will be extended to define `oplax_functor`.
-/
structure prepseudofunctor
  (B : Type u₁) [quiver.{v₁+1} B] [∀ a b : B, quiver.{w₁+1} (a ⟶ b)]
  (C : Type u₂) [quiver.{v₂+1} C] [∀ a b : C, quiver.{w₂+1} (a ⟶ b)]
  extends prefunctor B C : Type (max w₁ w₂ v₁ v₂ u₁ u₂) :=
(map₂ {a b : B} {f g : a ⟶ b} : (f ⟶ g) → (map f ⟶ map g))

/-- The prefunctor between the underlying quivers. -/
add_decl_doc prepseudofunctor.to_prefunctor

variables {B : Type u₁} [quiver.{v₁+1} B] [∀ a b : B, quiver.{w₁+1} (a ⟶ b)]
variables {C : Type u₂} [quiver.{v₂+1} C] [∀ a b : C, quiver.{w₂+1} (a ⟶ b)]
variables (F : prepseudofunctor B C)

@[simp] lemma prepseudofunctor.to_prefunctor_obj : F.to_prefunctor.obj = F.obj := rfl
@[simp] lemma prepseudofunctor.to_prefunctor_map : F.to_prefunctor.map = F.map := rfl

end

namespace prepseudofunctor

section
variables (B : Type u₁) [quiver.{v₁+1} B] [∀ a b : B, quiver.{w₁+1} (a ⟶ b)]

/-- The identity prepseudofunctor. -/
@[simps]
def id : prepseudofunctor B B :=
{ map₂ := λ a b f g η, η, .. prefunctor.id B }

instance : inhabited (prepseudofunctor B B) := ⟨prepseudofunctor.id B⟩

end

section
variables {B : Type u₁} [quiver.{v₁+1} B] [∀ a b : B, quiver.{w₁+1} (a ⟶ b)]
variables {C : Type u₂} [quiver.{v₂+1} C] [∀ a b : C, quiver.{w₂+1} (a ⟶ b)]
variables {D : Type u₃} [quiver.{v₃+1} D] [∀ a b : D, quiver.{w₃+1} (a ⟶ b)]
variables (F : prepseudofunctor B C) (G : prepseudofunctor C D)

/-- Composition of prepseudofunctors. -/
@[simps]
def comp : prepseudofunctor B D :=
{ map₂ := λ a b f g η, G.map₂ (F.map₂ η), .. F.to_prefunctor.comp G.to_prefunctor }

end

end prepseudofunctor

section

/--
This auxiliary definition claims that pseudofunctors preserve the associators
modulo some adjustments of domains and codomains of 2-morphisms. -/
/-
The reason for using this auxiliary definition instead of writing it directly in the definition
of pseudofunctors is that doing so will cause a timeout.
-/
@[simp]
def oplax_functor.map₂_associator_aux
  {B : Type u₁} [bicategory.{w₁ v₁} B] {C : Type u₂} [bicategory.{w₂ v₂} C]
  (obj : B → C) (map : Π {X Y : B}, (X ⟶ Y) → (obj X ⟶ obj Y))
  (map₂ : Π {a b : B} {f g : a ⟶ b}, (f ⟶ g) → (map f ⟶ map g))
  (map_comp : Π {a b c : B} (f : a ⟶ b) (g : b ⟶ c),  map (f ≫ g) ⟶ map f ≫ map g)
  {a b c d : B} (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d) : Prop :=
map₂ (α_ f g h).hom ≫ map_comp f (g ≫ h) ≫ (map f ◁ map_comp g h) =
  map_comp (f ≫ g) h ≫ (map_comp f g ▷ map h) ≫ (α_ (map f) (map g) (map h)).hom

/--
An oplax functor `F` between bicategories `B` and `C` consists of functions between objects,
1-morphisms, and 2-morphisms.

Unlike functors between categories, functions between 1-morphisms do not need to strictly commute
with compositions, and do not need to strictly preserve the identity. Instead, there are
specified 2-morphisms `F.map (𝟙 a) ⟶ 𝟙 (F.obj a)` and `F.map (f ≫ g) ⟶ F.map f ≫ F.map g`.

Functions between 2-morphisms strictly commute with compositions and preserve the identity.
They also preserve the associator, the left unitor, and the right unitor modulo some adjustments
of domains and codomains of 2-morphisms.
-/
structure oplax_functor (B : Type u₁) [bicategory.{w₁ v₁} B] (C : Type u₂) [bicategory.{w₂ v₂} C]
  extends prepseudofunctor B C : Type (max w₁ w₂ v₁ v₂ u₁ u₂) :=
(map_id (a : B) : map (𝟙 a) ⟶ 𝟙 (obj a))
(map_comp {a b c : B} (f : a ⟶ b) (g : b ⟶ c) : map (f ≫ g) ⟶ map f ≫ map g)
(map_comp_naturality_left' : ∀ {a b c : B} {f f' : a ⟶ b} (η : f ⟶ f') (g : b ⟶ c),
  map₂ (η ▷ g) ≫ map_comp f' g = map_comp f g ≫ (map₂ η ▷ map g) . obviously)
(map_comp_naturality_right' : ∀ {a b c : B} (f : a ⟶ b) {g g' : b ⟶ c} (η : g ⟶ g'),
  map₂ (f ◁ η) ≫ map_comp f g' = map_comp f g ≫ (map f ◁ map₂ η) . obviously)
(map₂_id' : ∀ {a b : B} (f : a ⟶ b), map₂ (𝟙 f) = 𝟙 (map f) . obviously)
(map₂_comp' : ∀ {a b : B} {f g h : a ⟶ b} (η : f ⟶ g) (θ : g ⟶ h),
  map₂ (η ≫ θ) = map₂ η ≫ map₂ θ . obviously)
(map₂_associator' : ∀ {a b c d : B} (f : a ⟶ b) (g : b ⟶ c) (h : c ⟶ d),
  oplax_functor.map₂_associator_aux obj (λ a b, map) (λ a b f g, map₂) (λ a b c, map_comp) f g h
    . obviously)
(map₂_left_unitor' : ∀ {a b : B} (f : a ⟶ b),
  map₂ (λ_ f).hom = map_comp (𝟙 a) f ≫ (map_id a ▷ map f) ≫ (λ_ (map f)).hom . obviously)
(map₂_right_unitor' : ∀ {a b : B} (f : a ⟶ b),
  map₂ (ρ_ f).hom = map_comp f (𝟙 b) ≫ (map f ◁ map_id b) ≫ (ρ_ (map f)).hom . obviously)

restate_axiom oplax_functor.map_comp_naturality_left'
restate_axiom oplax_functor.map_comp_naturality_right'
restate_axiom oplax_functor.map₂_id'
restate_axiom oplax_functor.map₂_comp'
restate_axiom oplax_functor.map₂_associator'
restate_axiom oplax_functor.map₂_left_unitor'
restate_axiom oplax_functor.map₂_right_unitor'
attribute [simp]
  oplax_functor.map_comp_naturality_left oplax_functor.map_comp_naturality_right
  oplax_functor.map₂_id oplax_functor.map₂_associator
attribute [reassoc]
  oplax_functor.map_comp_naturality_left oplax_functor.map_comp_naturality_right
  oplax_functor.map₂_comp oplax_functor.map₂_associator
  oplax_functor.map₂_left_unitor oplax_functor.map₂_right_unitor
attribute [simp]
  oplax_functor.map₂_comp oplax_functor.map₂_left_unitor oplax_functor.map₂_right_unitor

end

namespace oplax_functor

section
variables {B : Type u₁} [bicategory.{w₁ v₁} B] {C : Type u₂} [bicategory.{w₂ v₂} C]
variables (F : oplax_functor B C)

/-- Function on 1-morphisms as a functor. -/
@[simps]
def map_functor (a b : B) : (a ⟶ b) ⥤ (F.obj a ⟶ F.obj b) :=
{ obj := λ f, F.map f,
  map := λ f g η, F.map₂ η }

/-- The prepseudofunctor between the underlying quivers. -/
add_decl_doc oplax_functor.to_prepseudofunctor

@[simp] lemma to_prepseudofunctor_map₂ : F.to_prepseudofunctor.map₂ = F.map₂ := rfl
@[simp] lemma to_prepseudofunctor_map : F.to_prepseudofunctor.map = F.map := rfl
@[simp] lemma to_prepseudofunctor_obj : F.to_prepseudofunctor.obj = F.obj := rfl

end

section
variables (B : Type u₁) [bicategory.{w₁ v₁} B]

/-- The identity oplax functor. -/
@[simps]
def id : oplax_functor B B :=
{ map_id := λ a,  𝟙 (𝟙 a),
  map_comp := λ a b c f g, 𝟙 (f ≫ g),
  .. prepseudofunctor.id B }

instance : inhabited (oplax_functor B B) := ⟨id B⟩

end

section
variables
{B : Type u₁} [bicategory.{w₁ v₁} B]
{C : Type u₂} [bicategory.{w₂ v₂} C]
{D : Type u₃} [bicategory.{w₃ v₃} D]
(F : oplax_functor B C) (G : oplax_functor C D)

/-- Composition of oplax functor. -/
@[simps]
def comp : oplax_functor B D :=
{ map_id := λ a,
    (G.map_functor _ _).map (F.map_id a) ≫ G.map_id (F.obj a),
  map_comp := λ a b c f g,
    (G.map_functor _ _).map (F.map_comp f g) ≫ G.map_comp (F.map f) (F.map g),
  map_comp_naturality_left' := λ a b c f f' η g, by
  { dsimp,
    slice_rhs 1 3
    { rw [←map_comp_naturality_left, ←map₂_comp_assoc,
          ←map_comp_naturality_left, map₂_comp_assoc] } },
  map_comp_naturality_right' := λ a b c f g g' η, by
  { dsimp,
    slice_rhs 1 3
    { rw [←map_comp_naturality_right, ←map₂_comp_assoc,
          ←map_comp_naturality_right, map₂_comp_assoc] } },
  map₂_associator' := λ a b c d f g h, by
  { dsimp, simp only [whisker_right_comp, assoc, whisker_left_comp],
    rw [←map_comp_naturality_left_assoc, ←map_comp_naturality_right_assoc, ←map₂_associator],
    simp only [←map₂_comp_assoc],
    rw ←map₂_associator },
  map₂_left_unitor' := λ a b f, by
  { dsimp, simp only [whisker_right_comp, assoc],
    rw [←map_comp_naturality_left_assoc, ←map₂_left_unitor],
    simp only [←map₂_comp],
    rw ←map₂_left_unitor },
  map₂_right_unitor' := λ a b f, by
  { dsimp, simp only [whisker_left_comp, assoc],
    rw [←map_comp_naturality_right_assoc, ←map₂_right_unitor],
    simp only [←map₂_comp],
    rw ←map₂_right_unitor },
  .. F.to_prepseudofunctor.comp G.to_prepseudofunctor }

end

end oplax_functor

end category_theory
