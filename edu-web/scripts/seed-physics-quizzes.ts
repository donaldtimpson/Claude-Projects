import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

// Video IDs from DB (positions 1–6, 8–21; positions 0 and 7 skipped)
const quizzes: {
  videoId: string;
  label: string;
  questions: { prompt: string; options: string[]; correctIndex: number; explanation: string }[];
}[] = [
  {
    videoId: "cmo1t2tzj0004ynpwhzgewzks",
    label: "Quiz 1: Units, Quantities, Vectors",
    questions: [
      { prompt: "Which is a vector?", options: ["Speed", "Mass", "Velocity", "Energy"], correctIndex: 2, explanation: "Students confuse speed vs velocity" },
      { prompt: "A vector can be zero if:", options: ["Its magnitude is zero", "Its direction is undefined", "It cancels another vector", "It has no units"], correctIndex: 0, explanation: "Clarifies zero vector concept" },
      { prompt: "Adding two equal vectors in opposite directions gives:", options: ["Double magnitude", "Zero vector", "Same vector", "Undefined"], correctIndex: 1, explanation: "Vector addition intuition" },
      { prompt: "Units of force:", options: ["kg", "m/s", "Newton", "Joule"], correctIndex: 2, explanation: "Unit confusion" },
      { prompt: "Significant figures indicate:", options: ["Units", "Precision", "Accuracy only", "Direction"], correctIndex: 1, explanation: "Precision vs accuracy confusion" },
      { prompt: "Dot product result:", options: ["Vector", "Scalar", "Zero always", "Unit vector"], correctIndex: 1, explanation: "Students mix dot/cross" },
      { prompt: "Cross product result:", options: ["Scalar", "Vector perpendicular", "Parallel vector", "Zero"], correctIndex: 1, explanation: "Common confusion" },
      { prompt: "Unit vector magnitude:", options: ["0", "1", "Depends", "Infinite"], correctIndex: 1, explanation: "Basic but important" },
      { prompt: "Converting units changes:", options: ["Physical quantity", "Numerical value only", "Both", "Neither"], correctIndex: 1, explanation: "Core idea" },
      { prompt: "Order-of-magnitude estimate:", options: ["Exact answer", "Rough scale", "Unit conversion", "Precision tool"], correctIndex: 1, explanation: "Students over-trust precision" },
    ],
  },
  {
    videoId: "cmo1t2u1h0006ynpwd825ekn6",
    label: "Quiz 2: Motion in 1D",
    questions: [
      { prompt: "Velocity zero but acceleration nonzero:", options: ["Impossible", "Possible", "Always zero", "Infinite"], correctIndex: 1, explanation: "At turning point misconception" },
      { prompt: "Constant velocity means:", options: ["Zero acceleration", "Zero velocity", "Increasing speed", "Changing direction"], correctIndex: 0, explanation: "Definition clarity" },
      { prompt: "Object speeding up:", options: ["Acceleration opposite velocity", "Same direction as velocity", "Zero acceleration", "Random"], correctIndex: 1, explanation: "Directional reasoning" },
      { prompt: "Area under v–t graph:", options: ["Acceleration", "Displacement", "Speed", "Force"], correctIndex: 1, explanation: "Graph interpretation" },
      { prompt: "Slope of x–t graph:", options: ["Acceleration", "Velocity", "Force", "Energy"], correctIndex: 1, explanation: "Common confusion" },
      { prompt: "Free fall ignores:", options: ["Gravity", "Air resistance", "Mass", "Time"], correctIndex: 1, explanation: "Model assumption" },
      { prompt: "Two objects dropped from same height (no air resistance):", options: ["Heavier lands first", "Same time", "Lighter faster", "Depends on height"], correctIndex: 1, explanation: "Classic misconception" },
      { prompt: "Constant acceleration graph (v–t):", options: ["Curve", "Straight line", "Horizontal", "Random"], correctIndex: 1, explanation: "Graph intuition" },
      { prompt: "Instantaneous velocity:", options: ["Average", "Slope at a point", "Total distance", "Zero"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Negative velocity means:", options: ["Slowing down", "Opposite direction", "Negative speed", "No motion"], correctIndex: 1, explanation: "Direction vs magnitude" },
    ],
  },
  {
    videoId: "cmo1t2u3h0008ynpwgzp9tfee",
    label: "Quiz 3: Motion in 2D",
    questions: [
      { prompt: "Horizontal velocity in projectile motion:", options: ["Changes", "Constant", "Zero", "Infinite"], correctIndex: 1, explanation: "Key independence idea" },
      { prompt: "At the highest point of projectile motion:", options: ["Velocity zero", "Vertical velocity zero", "Acceleration zero", "Speed zero"], correctIndex: 1, explanation: "Very common error" },
      { prompt: "Gravity affects:", options: ["Horizontal motion", "Vertical motion only", "Both equally", "Neither"], correctIndex: 1, explanation: "Decoupling misconception" },
      { prompt: "Object dropped vs thrown horizontally from same height:", options: ["Land different times", "Same time", "One floats", "Depends on speed"], correctIndex: 1, explanation: "Horizontal independence" },
      { prompt: "Circular motion requires:", options: ["No force", "Inward force", "Outward force", "Zero acceleration"], correctIndex: 1, explanation: "Centripetal idea" },
      { prompt: "Velocity in circular motion:", options: ["Radial", "Tangential", "Zero", "Constant direction"], correctIndex: 1, explanation: "Direction confusion" },
      { prompt: "Speed constant in a circle means:", options: ["No acceleration", "Acceleration exists", "Zero force", "Motion stops"], correctIndex: 1, explanation: "Acceleration ≠ speed change" },
      { prompt: "Relative velocity depends on:", options: ["Object only", "Observer only", "Both", "Neither"], correctIndex: 2, explanation: "Frame dependence" },
      { prompt: "Range of a projectile depends on:", options: ["Speed only", "Angle only", "Both speed and angle", "Gravity only"], correctIndex: 2, explanation: "Multi-variable reasoning" },
      { prompt: "Acceleration vector in circular motion:", options: ["Tangential", "Toward center", "Zero", "Random"], correctIndex: 1, explanation: "Centripetal direction" },
    ],
  },
  {
    videoId: "cmo1t2u5g000aynpwairbzls7",
    label: "Quiz 4: Newton's Laws",
    questions: [
      { prompt: "Object moving at constant velocity:", options: ["Net force present", "Net force zero", "Acceleration present", "Force increasing"], correctIndex: 1, explanation: "Students think motion needs force" },
      { prompt: "Mass measures:", options: ["Weight", "Inertia", "Force", "Energy"], correctIndex: 1, explanation: "Key concept" },
      { prompt: "Action-reaction pairs act on:", options: ["Cancel each other out", "The same object", "Different objects", "Unequal forces"], correctIndex: 2, explanation: "Big misconception" },
      { prompt: "Heavier object in free fall (no air):", options: ["Falls faster", "Falls same as lighter", "Falls slower", "Stops"], correctIndex: 1, explanation: "Reinforce earlier" },
      { prompt: "Net force direction matches:", options: ["Velocity direction", "Acceleration direction", "Position", "Mass"], correctIndex: 1, explanation: "Important distinction" },
      { prompt: "Free-body diagram shows:", options: ["Motion", "Forces only", "Velocity", "Energy"], correctIndex: 1, explanation: "Students add motion arrows" },
      { prompt: "If net force doubles:", options: ["Acceleration halves", "Acceleration doubles", "Velocity doubles instantly", "Mass changes"], correctIndex: 1, explanation: "F=ma" },
      { prompt: "Weight equals:", options: ["Mass", "mg", "Velocity", "Force independent of gravity"], correctIndex: 1, explanation: "Clarify weight" },
      { prompt: "Normal force is:", options: ["Always mg", "Perpendicular contact force", "Zero always", "Parallel"], correctIndex: 1, explanation: "Common mistake" },
      { prompt: "Friction acts in the direction that:", options: ["Matches motion", "Opposes motion", "Is always backward", "Is always forward"], correctIndex: 1, explanation: "Nuance" },
    ],
  },
  {
    videoId: "cmo1t2u9q000cynpwgtqi7ic3",
    label: "Quiz 5: Applying Newton's Laws",
    questions: [
      { prompt: "Equilibrium means:", options: ["No motion", "Net force zero", "Zero velocity", "No forces"], correctIndex: 1, explanation: "Static vs dynamic confusion" },
      { prompt: "Static friction:", options: ["Constant", "Adjusts up to max", "Zero", "Infinite"], correctIndex: 1, explanation: "Key misconception" },
      { prompt: "Kinetic friction compared to static friction:", options: ["Greater than static", "Less than static typically", "Zero", "Infinite"], correctIndex: 1, explanation: "Common reversal" },
      { prompt: "Circular motion requires a force that is:", options: ["Outward", "Inward", "Zero", "Tangential"], correctIndex: 1, explanation: "Centripetal again" },
      { prompt: "Tension in a rope:", options: ["Pushes", "Pulls along rope", "Random", "Zero"], correctIndex: 1, explanation: "Basic but often missed" },
      { prompt: "Faster circular motion requires:", options: ["Less force", "More force", "Same force", "Zero force"], correctIndex: 1, explanation: "Speed-force relation" },
      { prompt: "Friction force depends on:", options: ["Contact area", "Normal force", "Speed only", "Mass only"], correctIndex: 1, explanation: "Area misconception" },
      { prompt: "Two objects with same force applied, different masses:", options: ["Same acceleration", "Smaller mass accelerates more", "Larger accelerates more", "No motion"], correctIndex: 1, explanation: "F=ma intuition" },
      { prompt: "Centripetal acceleration points:", options: ["Outward", "Toward center", "Zero", "Tangentially"], correctIndex: 1, explanation: "Direction again" },
      { prompt: "How many fundamental forces are there?", options: ["One", "Two", "Four (gravity, EM, strong, weak)", "Infinite"], correctIndex: 2, explanation: "Conceptual" },
    ],
  },
  {
    videoId: "cmo1t2ubp000eynpwfv0atv6o",
    label: "Quiz 6: Work & Kinetic Energy",
    questions: [
      { prompt: "A force is applied to a box, but it does not move. What is the work done?", options: ["Positive", "Negative", "Zero", "Depends on force magnitude"], correctIndex: 2, explanation: "\"Force alone does work\" misconception" },
      { prompt: "You push a box forward while friction acts backward. What is the work done by friction?", options: ["Positive", "Zero", "Negative", "Depends on speed"], correctIndex: 2, explanation: "Friction \"just resists\" but doesn't do work" },
      { prompt: "Two objects move at the same speed; one has twice the mass. Which has more KE?", options: ["Same KE", "Heavier has twice as much KE", "Heavier has four times", "Depends on acceleration"], correctIndex: 1, explanation: "Misconception: KE depends only on speed" },
      { prompt: "You double your speed. KE becomes:", options: ["2×", "3×", "4×", "Unchanged"], correctIndex: 2, explanation: "Classic square dependence trap" },
      { prompt: "A force acts perpendicular to motion. Work is:", options: ["Positive", "Negative", "Zero", "Maximum"], correctIndex: 2, explanation: "Misconception: any force does work" },
      { prompt: "If net work on an object is zero, its speed:", options: ["Must be zero", "Must change", "Remains constant", "Becomes infinite"], correctIndex: 2, explanation: "Misconception: zero work means no motion" },
      { prompt: "Lifting a book at constant speed — net work done on the book:", options: ["Positive", "Negative", "Zero", "Depends on height"], correctIndex: 2, explanation: "Students forget gravity cancels applied work" },
      { prompt: "Power measures:", options: ["Force", "Energy", "Rate of doing work", "Acceleration"], correctIndex: 2, explanation: "Misconception: power = energy" },
      { prompt: "Heavier object moving at the same speed as a lighter one:", options: ["Same KE", "More KE", "Less KE", "No KE"], correctIndex: 1, explanation: "Reinforces KE ∝ mass" },
      { prompt: "A sliding object slows due to friction. Its KE:", options: ["Increases", "Remains constant", "Decreases", "Becomes zero instantly"], correctIndex: 2, explanation: "Misconception: energy disappears instantly" },
    ],
  },
  {
    videoId: "cmo1t2ufm000iynpwmnvn1wjs",
    label: "Quiz 7: Energy Conservation",
    questions: [
      { prompt: "Ball thrown upward — at the top, its energy is:", options: ["All KE", "All PE", "Zero", "Lost"], correctIndex: 1, explanation: "Misconception: energy \"disappears\" at top" },
      { prompt: "In the absence of friction:", options: ["KE is conserved", "PE is conserved", "Total mechanical energy is conserved", "None is conserved"], correctIndex: 2, explanation: "Key distinction" },
      { prompt: "Path independence means:", options: ["Energy depends on distance traveled", "Only endpoints matter", "Force is zero", "Motion stops"], correctIndex: 1, explanation: "Misconception: longer path = more energy" },
      { prompt: "Friction causes:", options: ["Energy to be lost from the universe", "Mechanical energy to decrease", "Energy to be destroyed", "No change"], correctIndex: 1, explanation: "Clarify energy vs mechanical energy" },
      { prompt: "Spring compressed more:", options: ["Less energy stored", "Same energy stored", "More energy stored", "No energy stored"], correctIndex: 2, explanation: "Misconception: linear vs quadratic" },
      { prompt: "At the lowest point of a pendulum's swing:", options: ["KE is maximum", "PE is maximum", "Both are zero", "Energy is zero"], correctIndex: 0, explanation: "Classic swap confusion" },
      { prompt: "A conservative force does:", options: ["Always small work", "Path-dependent work", "Path-independent work", "Zero work"], correctIndex: 2, explanation: "Terminology confusion" },
      { prompt: "If mechanical energy decreases, the lost energy is:", options: ["Gone from the universe", "Destroyed", "Converted to thermal/internal energy", "Impossible"], correctIndex: 2, explanation: "Important conceptual distinction" },
      { prompt: "Going down a steeper path vs. a gradual path (same height):", options: ["More energy gained on steeper", "Same energy gained", "Less energy on steeper", "Depends on speed"], correctIndex: 1, explanation: "Common intuition trap" },
      { prompt: "Energy diagrams show:", options: ["Time", "Force", "Energy vs position", "Velocity"], correctIndex: 2, explanation: "Students mix graph meanings" },
    ],
  },
  {
    videoId: "cmo1t2uhl000kynpw0k18w0o5",
    label: "Quiz 8: Momentum & Collisions",
    questions: [
      { prompt: "Truck and car at same speed — who has more momentum?", options: ["Same", "Car", "Truck", "Depends on acceleration"], correctIndex: 2, explanation: "Mass dependence" },
      { prompt: "Impulse changes an object's:", options: ["Velocity", "Momentum", "Energy only", "Mass"], correctIndex: 1, explanation: "Definition confusion" },
      { prompt: "With no external force, what is conserved?", options: ["Energy", "Momentum", "Velocity", "Acceleration"], correctIndex: 1, explanation: "Students mix conservation laws" },
      { prompt: "Two objects collide and stick together. This is:", options: ["Elastic", "Inelastic", "Perfectly inelastic", "Not a collision"], correctIndex: 2, explanation: "Terminology trap" },
      { prompt: "In an elastic collision:", options: ["KE is lost", "KE is conserved", "Momentum is lost", "Mass changes"], correctIndex: 1, explanation: "Key definition" },
      { prompt: "Heavier object in a collision:", options: ["Always stops", "Changes velocity less", "Changes velocity more", "Same change as lighter"], correctIndex: 1, explanation: "Momentum intuition" },
      { prompt: "Increasing collision time (e.g., airbags):", options: ["Increases force", "Decreases force", "No effect", "Increases momentum"], correctIndex: 1, explanation: "Airbags misconception" },
      { prompt: "A rocket accelerates by:", options: ["Pushing against air", "Gravity", "Conservation of momentum", "Creating energy"], correctIndex: 2, explanation: "Classic misconception" },
      { prompt: "Center of mass motion depends on:", options: ["Internal forces", "External forces only", "Velocity", "Mass only"], correctIndex: 1, explanation: "Important system thinking" },
      { prompt: "Action-reaction (equal and opposite) forces:", options: ["Cancel motion", "Act on different objects", "Stop motion", "Remove energy"], correctIndex: 1, explanation: "Newton's 3rd confusion again" },
    ],
  },
  {
    videoId: "cmo1t2ujk000mynpwv6r3h8hi",
    label: "Quiz 9: Rotation of Rigid Bodies",
    questions: [
      { prompt: "Mass farther from the rotation axis:", options: ["Easier to rotate", "Harder to rotate", "No effect", "Stops rotation"], correctIndex: 1, explanation: "Moment of inertia intuition" },
      { prompt: "Angular velocity is the rotational analog of:", options: ["Force", "Linear velocity", "Energy", "Mass"], correctIndex: 1, explanation: "Analogy building" },
      { prompt: "Rolling without slipping requires:", options: ["v ≠ rω", "v = rω", "v = 0", "ω = 0"], correctIndex: 1, explanation: "Core condition" },
      { prompt: "Same force applied at larger radius gives:", options: ["Less rotation", "More torque", "Same torque", "Zero torque"], correctIndex: 1, explanation: "Torque intuition" },
      { prompt: "Rotational KE depends on:", options: ["ω only", "ω² and I", "mass only", "radius only"], correctIndex: 1, explanation: "Parallel to linear KE" },
      { prompt: "Object spinning faster has:", options: ["More KE", "Less KE", "Same KE", "Zero KE"], correctIndex: 0, explanation: "Reinforce energy relation" },
      { prompt: "Two objects same mass but different shapes:", options: ["Same moment of inertia", "Different moment of inertia", "Same motion always", "Zero inertia"], correctIndex: 1, explanation: "Shape matters" },
      { prompt: "Angular acceleration is:", options: ["Change in angle", "Change in angular velocity", "Force", "Energy"], correctIndex: 1, explanation: "Definition clarity" },
      { prompt: "Units of angular velocity ω:", options: ["m/s", "rad/s", "N", "J"], correctIndex: 1, explanation: "Basic but commonly mixed" },
      { prompt: "Rotation requires:", options: ["Force", "Torque", "Mass", "Velocity"], correctIndex: 1, explanation: "Distinguishing concepts" },
    ],
  },
  {
    videoId: "cmo1t2umj000oynpw1uhcjwyp",
    label: "Quiz 10: Rotational Dynamics",
    questions: [
      { prompt: "Torque depends on:", options: ["Force only", "Distance only", "Force and lever arm", "Mass"], correctIndex: 2, explanation: "Common oversight" },
      { prompt: "Zero net torque means:", options: ["No motion", "Constant angular velocity", "Zero velocity", "Infinite motion"], correctIndex: 1, explanation: "Same as linear case confusion" },
      { prompt: "An ice skater pulls their arms in. They:", options: ["Slow down", "Speed up", "Stop", "Stay same speed"], correctIndex: 1, explanation: "Angular momentum conservation" },
      { prompt: "Angular momentum is conserved when:", options: ["No forces act", "No net torque acts", "No motion occurs", "Speed is constant"], correctIndex: 1, explanation: "Students confuse force vs torque" },
      { prompt: "Increasing moment of inertia I while angular momentum L is constant:", options: ["ω increases", "ω decreases", "No change to ω", "Infinite ω"], correctIndex: 1, explanation: "Inverse relationship" },
      { prompt: "Work done by torque equals:", options: ["τθ", "Fd", "mv", "ω²"], correctIndex: 0, explanation: "Parallel to linear work" },
      { prompt: "Gyroscope stability is due to:", options: ["Mass", "Angular momentum", "Friction", "Gravity"], correctIndex: 1, explanation: "Key concept" },
      { prompt: "Torque direction affects:", options: ["Speed", "Direction of angular momentum", "Mass", "Energy only"], correctIndex: 1, explanation: "Vector nature" },
      { prompt: "Precession occurs because:", options: ["No torque acts", "Torque changes direction of L", "Zero motion", "Infinite speed"], correctIndex: 1, explanation: "Subtle concept" },
      { prompt: "Rotational power equals:", options: ["τω", "Fv", "mv", "ω²"], correctIndex: 0, explanation: "Analogy reinforcement" },
    ],
  },
  {
    videoId: "cmo1t2uog000qynpw5z2i0q5p",
    label: "Quiz 11: Equilibrium & Elasticity",
    questions: [
      { prompt: "An object in equilibrium has:", options: ["No forces acting", "Net force and net torque both zero", "No motion", "Zero energy"], correctIndex: 1, explanation: "Static vs dynamic" },
      { prompt: "Stable equilibrium means the object:", options: ["Moves away when displaced", "Returns after displacement", "Never moves", "Behaves randomly"], correctIndex: 1, explanation: "Stability concept" },
      { prompt: "Center of gravity:", options: ["Is always the geometric center", "Depends on mass distribution", "Is always zero", "Is always fixed"], correctIndex: 1, explanation: "Misconception" },
      { prompt: "Stress is defined as:", options: ["Force", "Force per unit area", "Area", "Velocity"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Strain is defined as:", options: ["Force", "Fractional deformation", "Mass", "Energy"], correctIndex: 1, explanation: "Definition" },
      { prompt: "Hooke's law is valid only for:", options: ["All deformations", "Small deformations", "Large deformations", "Never"], correctIndex: 1, explanation: "Limit awareness" },
      { prompt: "A larger Young's modulus means:", options: ["Softer material", "Stiffer material", "More mass", "Less force needed"], correctIndex: 1, explanation: "Interpretation" },
      { prompt: "Plastic deformation is:", options: ["Reversible", "Permanent", "Zero", "Elastic"], correctIndex: 1, explanation: "Key distinction" },
      { prompt: "Torque balance prevents:", options: ["Translation", "Rotation", "Energy change", "Mass change"], correctIndex: 1, explanation: "Concept separation" },
      { prompt: "Exceeding the elastic limit results in:", options: ["Return to original shape", "Permanent deformation", "Zero force", "Infinite stretch"], correctIndex: 1, explanation: "Material behavior" },
    ],
  },
  {
    videoId: "cmo1t2uqj000synpwev03msp5",
    label: "Quiz 12: Fluids",
    questions: [
      { prompt: "Pressure increases with depth because of:", options: ["More volume", "Weight of fluid above", "Increasing area", "Zero density"], correctIndex: 1, explanation: "" },
      { prompt: "An object floats when:", options: ["Weight > buoyant force", "Its density < fluid density", "Its volume is large", "Force is zero"], correctIndex: 1, explanation: "" },
      { prompt: "Faster-moving fluid has:", options: ["Higher pressure", "Lower pressure", "Same pressure", "Zero pressure"], correctIndex: 1, explanation: "" },
      { prompt: "Buoyant force depends on:", options: ["Object's weight", "Weight of fluid displaced", "Shape only", "Speed"], correctIndex: 1, explanation: "" },
      { prompt: "Viscosity resists:", options: ["Flow", "Pressure", "Mass", "Energy"], correctIndex: 0, explanation: "" },
    ],
  },
  {
    videoId: "cmo1t2usg000uynpw03fc2uk1",
    label: "Quiz 13: Gravitation",
    questions: [
      { prompt: "Doubling the distance between two masses changes the gravitational force to:", options: ["2×", "4×", "1/4×", "Same"], correctIndex: 2, explanation: "" },
      { prompt: "An orbiting satellite:", options: ["Has no acceleration", "Accelerates inward", "Moves in a straight line", "Experiences zero force"], correctIndex: 1, explanation: "" },
      { prompt: "An astronaut feeling weightless in orbit is because:", options: ["There is no gravity", "Gravity exists but they are in free fall", "Gravity is infinite", "There is no motion"], correctIndex: 1, explanation: "" },
      { prompt: "Escape velocity depends on:", options: ["Mass of object only", "Radius only", "Both mass of planet and radius", "Neither"], correctIndex: 2, explanation: "" },
      { prompt: "Gravity always:", options: ["Repels", "Attracts", "Is zero", "Is random"], correctIndex: 1, explanation: "" },
    ],
  },
  {
    videoId: "cmo1t2uuh000wynpwgqquqr25",
    label: "Quiz 14: Simple Harmonic Motion",
    questions: [
      { prompt: "Maximum speed in SHM occurs:", options: ["At maximum displacement", "At equilibrium position", "Anywhere", "Nowhere"], correctIndex: 1, explanation: "" },
      { prompt: "Acceleration in SHM is:", options: ["In same direction as displacement", "In opposite direction to displacement", "Zero", "Random"], correctIndex: 1, explanation: "" },
      { prompt: "Period of oscillation depends on:", options: ["Amplitude", "Physical properties of the system", "Speed", "Energy"], correctIndex: 1, explanation: "" },
      { prompt: "Damping causes:", options: ["Increased energy", "Decreased amplitude", "No effect", "Infinite oscillation"], correctIndex: 1, explanation: "" },
      { prompt: "Resonance is:", options: ["Random motion", "Large amplitude at natural frequency", "No motion", "Constant force"], correctIndex: 1, explanation: "" },
    ],
  },
  {
    videoId: "cmo1t2uwd000yynpwwh67p9ep",
    label: "Quiz 15: Mechanical Waves",
    questions: [
      { prompt: "Waves transfer:", options: ["Matter", "Energy", "Mass", "Charge"], correctIndex: 1, explanation: "" },
      { prompt: "Higher amplitude means:", options: ["Higher energy", "Higher speed", "Higher frequency", "No change"], correctIndex: 0, explanation: "" },
      { prompt: "If frequency increases (speed constant), wavelength:", options: ["Increases", "Decreases", "Goes to zero", "No effect"], correctIndex: 1, explanation: "" },
      { prompt: "Nodes in a standing wave have:", options: ["Maximum displacement", "Zero displacement", "Maximum speed", "Maximum energy"], correctIndex: 1, explanation: "" },
      { prompt: "Superposition means waves:", options: ["Cancel each other always", "Add together", "Have no interaction", "Stop"], correctIndex: 1, explanation: "" },
    ],
  },
  {
    videoId: "cmo1t2uyc0010ynpwgjjl1k79",
    label: "Quiz 16: Sound Waves",
    questions: [
      { prompt: "Pitch of a sound depends on:", options: ["Amplitude", "Frequency", "Speed", "Energy"], correctIndex: 1, explanation: "" },
      { prompt: "Loudness of a sound depends on:", options: ["Frequency", "Amplitude", "Speed", "Time"], correctIndex: 1, explanation: "" },
      { prompt: "Sound cannot travel through:", options: ["Air", "Water", "Vacuum", "Steel"], correctIndex: 2, explanation: "" },
      { prompt: "The Doppler effect refers to:", options: ["Speed change", "Frequency shift due to relative motion", "Amplitude change", "Energy loss"], correctIndex: 1, explanation: "" },
      { prompt: "Beats are produced by:", options: ["Same frequency waves", "Waves of close but different frequencies", "Silence", "Random noise"], correctIndex: 1, explanation: "" },
    ],
  },
  {
    videoId: "cmo1t2v150012ynpw1f14v9k3",
    label: "Quiz 17: Temperature & Heat",
    questions: [
      { prompt: "Heat naturally flows:", options: ["Cold → hot", "Hot → cold", "Randomly", "Not at all"], correctIndex: 1, explanation: "" },
      { prompt: "Temperature measures:", options: ["Total energy", "Average kinetic energy of molecules", "Heat", "Force"], correctIndex: 1, explanation: "" },
      { prompt: "During a phase change, temperature:", options: ["Rises", "Remains constant", "Goes to zero", "Goes to infinite"], correctIndex: 1, explanation: "" },
      { prompt: "Conduction transfers heat by:", options: ["Fluid motion", "Direct contact", "Radiation", "None of these"], correctIndex: 1, explanation: "" },
      { prompt: "Radiation:", options: ["Needs a medium", "Needs no medium", "Requires contact", "Is zero in space"], correctIndex: 1, explanation: "" },
    ],
  },
  {
    videoId: "cmo1t2v320014ynpwtxfdp71w",
    label: "Quiz 18: Thermal Properties of Matter",
    questions: [
      { prompt: "Gas pressure arises from:", options: ["Gravity", "Molecular collisions with walls", "Volume", "Energy"], correctIndex: 1, explanation: "" },
      { prompt: "Higher temperature means molecules move:", options: ["Slower", "Faster", "The same", "They stop"], correctIndex: 1, explanation: "" },
      { prompt: "The ideal gas model assumes:", options: ["Molecular interactions", "No molecular interactions", "Infinite forces", "Massless molecules"], correctIndex: 1, explanation: "" },
      { prompt: "Absolute zero is:", options: ["0°C", "0 K", "Infinite temperature", "None of these"], correctIndex: 1, explanation: "" },
      { prompt: "Heat capacity is:", options: ["Force", "Energy per unit temperature change", "Velocity", "Time"], correctIndex: 1, explanation: "" },
    ],
  },
  {
    videoId: "cmo1t2v570016ynpw2kxckh6m",
    label: "Quiz 19: First Law of Thermodynamics",
    questions: [
      { prompt: "ΔU = Q − W expresses:", options: ["Energy creation", "Conservation of energy", "Newton's force law", "A motion law"], correctIndex: 1, explanation: "" },
      { prompt: "An adiabatic process involves:", options: ["Heat added", "No heat transfer", "Constant temperature", "Zero work"], correctIndex: 1, explanation: "" },
      { prompt: "An isothermal process is one at:", options: ["Constant temperature", "Constant pressure", "No heat transfer", "Zero work"], correctIndex: 0, explanation: "" },
      { prompt: "When a gas is compressed:", options: ["Work is done by the gas", "Work is done on the gas", "No work is done", "Infinite work"], correctIndex: 1, explanation: "" },
      { prompt: "For a complete thermodynamic cycle:", options: ["ΔU ≠ 0", "ΔU = 0", "Infinite energy", "No work"], correctIndex: 1, explanation: "" },
    ],
  },
  {
    videoId: "cmo1t2v730018ynpwdg2nm10q",
    label: "Quiz 20: Second Law of Thermodynamics",
    questions: [
      { prompt: "Entropy is a measure of:", options: ["Energy", "Disorder", "Force", "Mass"], correctIndex: 1, explanation: "" },
      { prompt: "A heat engine converts:", options: ["Work into heat", "Heat into work", "No energy", "Infinite energy"], correctIndex: 1, explanation: "" },
      { prompt: "The efficiency of any real heat engine is:", options: ["100%", "Less than 100%", "Greater than 100%", "Zero"], correctIndex: 1, explanation: "" },
      { prompt: "Heat naturally flows:", options: ["Cold → hot", "Hot → cold", "Randomly", "None of these"], correctIndex: 1, explanation: "" },
      { prompt: "In an isolated system, entropy:", options: ["Decreases", "Increases or stays constant", "Is always zero", "Is infinite"], correctIndex: 1, explanation: "" },
    ],
  },
];

async function main() {
  console.log("Seeding physics quizzes...");
  let total = 0;

  for (const quiz of quizzes) {
    const created = await prisma.quizQuestion.createMany({
      data: quiz.questions.map((q, i) => ({
        videoId: quiz.videoId,
        prompt: q.prompt,
        options: q.options,
        correctIndex: q.correctIndex,
        explanation: q.explanation,
        position: i,
      })),
    });
    console.log(`  ${quiz.label}: ${created.count} questions`);
    total += created.count;
  }

  console.log(`Done — ${total} questions inserted across ${quizzes.length} videos.`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
