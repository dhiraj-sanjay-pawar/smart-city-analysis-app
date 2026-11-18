# SmartCity Citizen App — UI Overhaul to Match Reference Designs

## Completed Features
1. **Asset Extraction & Integration**:
   - Extracted all required image assets directly from the user's reference designs into `assets/images/`:
     - `hero_banner.png`: "Together for a Better City" river & city bridge photo banner
     - `service_traffic.png`: Busy street traffic photo
     - `service_healthcare.png`: Hospital exterior building photo
     - `hospital_camp.png`: Free Health Camp bus/facility photo
     - `hospital_firstaid.png`: First Aid Clinic photo
     - `complaint_streetlight.png`: Broken streetlights night photo
     - `complaint_garbage.png`: Overflowing garbage photo
     - `complaint_pothole.png`: Road pothole photo
     - `nashik_map_bg.png`: Full high-fidelity Nashik GIS styled map background
     - `header_skyline.png`: File a Complaint header skyline graphic
     - 8 Category photo cards: `cat_road.png`, `cat_water.png`, `cat_electricity.png`, `cat_sanitation.png`, `cat_crime.png`, `cat_wastewater.png`, `cat_traffic.png`, `cat_other.png`
   - Added assets directory declaration in `pubspec.yaml`.

2. **Image 1 — Home Dashboard Screen**:
   - Header with "Good Morning ☀️", large bold "Rahul", notification bell with red badge "3", circular teal avatar "RS".
   - Rounded search bar: "Search services, hospitals, complaints..." with filter sliders icon.
   - Emergency Alert banner (`#FEF2F2` container with red speaker/megaphone icon, Nashik Godavari River flash flood warning, red arrow).
   - "Together for a Better City" hero banner with "Clean & Safe City" tag, "Cleaner Streets • Safer Roads • Healthier Lives", "Explore Services ->" pill button, and 3 pagination dots.
   - "Our Services" dual cards: Traffic Management (blue car icon, arrow, subtitle, bottom photo) & Healthcare Services (teal cross icon, arrow, subtitle, bottom photo).
   - "Nearby Hospitals": Free Health Camp – Ward 12 ("Free" badge, 0.3 km) & First Aid Centre – Gandhi Nagar ("24/7" badge, 0.5 km).
   - "Recent Complaints": 3 cards matching Image 1: Broken streetlights on Nehru Avenue (Submitted), Overflowing garbage near market (In Progress), Large pothole on MG Road (In Progress).
   - Floating "+ Report Issue" orange pill button (`#F97316`).
   - Bottom navigation bar: Home, Map, My Reports, Profile.

3. **Image 2 — Smart City Map Screen**:
   - Map icon + "Smart City Map" + "📍 Nashik City" status tag.
   - Horizontal filter pills: "All", "🚦 Traffic", "➕ Hospitals", "🔧 Complaints", "💧 Water".
   - Realistic Nashik map showing Godavari River, M.G. Road, College Road, Shivaji Nagar, Central Park, Panchavati, Nashik Road.
   - Map controls: GPS crosshairs re-center button & Zoom (+ / -) pill.
   - Interactive animated markers with colored glowing pulse rings and pins.
   - Collapsible bottom-left "Map Legend" card.
   - Tapping any marker opens an interactive bottom sheet with details, directions, and actions.

4. **Image 3 — File a Complaint Screen**:
   - Skyline illustration background header with back arrow and "File a Complaint" in white.
   - Municipal grievance notice banner without "Demo" word.
   - 8 Photo Category Cards (4x2 grid) with real photos, overlapping round icon badges, and golden selection highlight.
   - Complaint Title with 'T' icon & Description with document icon.
   - Two Location Options:
     - "📍 Use My Live Location" via GPS permission with `geolocator`.
     - "✏️ Enter Location Manually" with editable field & quick Nashik landmarks.
   - Photo Attachments via `image_picker`: Camera & Gallery picker, horizontal preview list with (X) remove button.
   - Teal `#0D9488` Submit Complaint button with animated success screen.

5. **Every Card Clickable with Specific Details**:
   - `EmergencyDetailsSheet`: Godavari River flood advisory, safety instructions, emergency helplines (1077, 112, 108).
   - `HospitalDetailsSheet`: Hospital photo, name, address, rating, specialties, call center, directions.
   - `ComplaintDetailsSheet`: Complaint photo, ID, status history timeline, description, notes.
   - `ExploreServicesSheet`: Grid of all municipal services.

6. **Real Verified Nashik Locations**:
   - Nashik District Civil Hospital, Apollo Hospitals Nashik, Sahyadri Super Speciality Hospital, Six Sigma Medicare, Wockhardt Hospital.
   - M.G. Road (CBS to Shalimar Chowk), College Road, Gangapur Road, Old Agra Road, Godavari Riverfront (Ramkund to Tapovan).
   - Removed all instances of the word "Demo".

7. **Code Quality & Testing**:
   - `flutter analyze`: **0 issues found**!
   - `flutter test`: **100% tests passing**!
