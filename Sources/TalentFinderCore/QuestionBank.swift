import Foundation

/// The full 60-item survey: 5 scale items per aptitude plus 10 "which would you rather" items.
public enum QuestionBank {
    public static let all: [Question] = scale + choices

    public static func question(id: String) -> Question? { byID[id] }

    private static let byID: [String: Question] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static let scale: [Question] = [
        // Analytical
        .agree("an1", "I enjoy puzzles that have one right answer, like Sudoku or logic problems.", [.analytical: 1]),
        .agree("an2", "When something goes wrong, I like to work out exactly why before fixing it.", [.analytical: 1, .handsOn: 0.3]),
        .agree("an3", "I find numbers and statistics boring.", [.analytical: 1], reversed: true),
        .ability("an4", "Doing mental arithmetic, like splitting a bill in your head", [.analytical: 1]),
        .ability("an5", "Spotting the flaw in someone's argument", [.analytical: 1, .verbal: 0.3]),

        // Words & Language
        .agree("ve1", "I often lose track of time when I'm reading.", [.verbal: 1]),
        .agree("ve2", "People tell me I explain things clearly.", [.verbal: 1, .social: 0.3]),
        .agree("ve3", "Writing even a short email feels like a chore.", [.verbal: 1], reversed: true),
        .ability("ve4", "Learning new words or picking up a foreign language", [.verbal: 1]),
        .ability("ve5", "Telling a story so that people stay hooked", [.verbal: 1, .creative: 0.3]),

        // Spatial & Visual
        .agree("sp1", "I can usually find my way back to a place I've only visited once.", [.spatial: 1]),
        .agree("sp2", "I can picture things in my head in detail — rooms, objects, diagrams.", [.spatial: 1, .creative: 0.3]),
        .agree("sp3", "Maps and diagrams confuse me.", [.spatial: 1], reversed: true),
        .ability("sp4", "Packing a car boot or a suitcase so everything fits", [.spatial: 1, .handsOn: 0.3]),
        .ability("sp5", "Imagining what an object looks like from the other side", [.spatial: 1]),

        // Musical & Rhythmic
        .agree("mu1", "I notice when a singer or instrument is slightly out of tune.", [.musical: 1]),
        .agree("mu2", "A tune I've heard once or twice stays in my head.", [.musical: 1]),
        .agree("mu3", "I rarely listen to music by choice.", [.musical: 1], reversed: true),
        .ability("mu4", "Clapping or tapping along in time with a song", [.musical: 1, .physical: 0.3]),
        .ability("mu5", "Picking out a melody by ear, on an instrument or by humming", [.musical: 1]),

        // Physical & Movement
        .agree("ph1", "I'd rather learn a new move by trying it than by reading about it.", [.physical: 1]),
        .agree("ph2", "I feel restless if I have to sit still for too long.", [.physical: 1]),
        .agree("ph3", "I'm usually one of the clumsier people in a group.", [.physical: 1], reversed: true),
        .ability("ph4", "Catching a ball that's thrown to you unexpectedly", [.physical: 1]),
        .ability("ph5", "Picking up a new sport or dance routine", [.physical: 1]),

        // People & Empathy
        .agree("so1", "Friends come to me when they need to talk something through.", [.social: 1]),
        .agree("so2", "I can usually tell how someone feels before they say anything.", [.social: 1]),
        .agree("so3", "I find it draining to help people with their problems.", [.social: 1], reversed: true),
        .ability("so4", "Making a nervous stranger feel at ease", [.social: 1]),
        .ability("so5", "Calming down an argument between two people", [.social: 1, .leadership: 0.3]),

        // Leading & Persuading
        .agree("le1", "In a group with no plan, I'm usually the one who suggests one.", [.leadership: 1]),
        .agree("le2", "I enjoy convincing people to see things my way.", [.leadership: 1, .verbal: 0.3]),
        .agree("le3", "I'd rather someone else made the final call.", [.leadership: 1], reversed: true),
        .ability("le4", "Speaking in front of a room full of people", [.leadership: 1, .verbal: 0.3]),
        .ability("le5", "Getting a team to agree on who does what", [.leadership: 1]),

        // Creative & Imaginative
        .agree("cr1", "I often come up with ideas nobody else has thought of.", [.creative: 1]),
        .agree("cr2", "I like making things — drawings, stories, recipes, outfits — just for fun.", [.creative: 1]),
        .agree("cr3", "I'd rather follow clear instructions than make something up.", [.creative: 1], reversed: true),
        .ability("cr4", "Thinking of lots of different uses for an everyday object", [.creative: 1]),
        .ability("cr5", "Sketching or designing something that looks good", [.creative: 1, .spatial: 0.3]),

        // Hands-on & Mechanical
        .agree("ha1", "I like taking things apart to see how they work.", [.handsOn: 1]),
        .agree("ha2", "I'd rather fix something myself than call someone in.", [.handsOn: 1]),
        .agree("ha3", "I avoid tools and DIY whenever I can.", [.handsOn: 1], reversed: true),
        .ability("ha4", "Following a flat-pack furniture diagram without mistakes", [.handsOn: 1, .spatial: 0.3]),
        .ability("ha5", "Working out why a machine or gadget has stopped working", [.handsOn: 1, .analytical: 0.3]),

        // Nature & Living Things
        .agree("na1", "I feel most like myself when I'm outdoors.", [.nature: 1]),
        .agree("na2", "I notice birds, plants or insects that other people walk straight past.", [.nature: 1]),
        .agree("na3", "Looking after plants or pets doesn't interest me.", [.nature: 1], reversed: true),
        .ability("na4", "Telling apart similar kinds of trees, birds or animals", [.nature: 1]),
        .ability("na5", "Keeping plants or animals healthy and thriving", [.nature: 1]),
    ]

    static let choices: [Question] = [
        .choice("ch1", "A free Saturday afternoon. Which sounds best?", [
            ("Cracking a tricky escape-room puzzle", [.analytical: 1]),
            ("Hiking somewhere you've never been", [.nature: 1, .physical: 0.5]),
            ("Jamming with friends or going to a gig", [.musical: 1, .social: 0.3]),
            ("Building or repairing something in the garage", [.handsOn: 1]),
        ]),
        .choice("ch2", "In a group project, you'd naturally take on…", [
            ("Running the plan and the deadlines", [.leadership: 1]),
            ("Writing the report and the presentation", [.verbal: 1]),
            ("Designing how it all looks", [.creative: 0.7, .spatial: 0.5]),
            ("Keeping everyone happy and talking", [.social: 1]),
        ]),
        .choice("ch3", "Which would you most like to learn this year?", [
            ("A musical instrument", [.musical: 1]),
            ("A martial art or a dance style", [.physical: 1]),
            ("Coding or data analysis", [.analytical: 1]),
            ("Woodwork or electronics", [.handsOn: 1]),
        ]),
        .choice("ch4", "Your ideal place to spend a working day…", [
            ("Outdoors, whatever the weather", [.nature: 1, .physical: 0.3]),
            ("A workshop full of tools", [.handsOn: 1]),
            ("A studio full of materials", [.creative: 1, .spatial: 0.3]),
            ("A busy room full of people", [.leadership: 0.7, .social: 0.5]),
        ]),
        .choice("ch5", "Which compliment would mean the most to you?", [
            ("\u{201C}You're so sharp — you figured it out!\u{201D}", [.analytical: 1]),
            ("\u{201C}You're a brilliant writer.\u{201D}", [.verbal: 1]),
            ("\u{201C}You've got a great eye.\u{201D}", [.spatial: 0.7, .creative: 0.5]),
            ("\u{201C}You always know what to say to people.\u{201D}", [.social: 1]),
        ]),
        .choice("ch6", "At a big museum, you head first to…", [
            ("The science and engineering hall", [.handsOn: 0.7, .analytical: 0.5]),
            ("The natural history wing", [.nature: 1]),
            ("The art gallery", [.creative: 0.7, .spatial: 0.5]),
            ("The history of music exhibition", [.musical: 1]),
        ]),
        .choice("ch7", "Pick a weekend course:", [
            ("Public speaking and negotiation", [.leadership: 1]),
            ("Creative writing", [.verbal: 0.7, .creative: 0.5]),
            ("Rock climbing", [.physical: 1, .nature: 0.3]),
            ("Wildlife photography", [.nature: 1, .spatial: 0.3]),
        ]),
        .choice("ch8", "When you have a hard problem to solve, you'd rather…", [
            ("Make a list of pros and cons, or a spreadsheet", [.analytical: 1]),
            ("Talk it through with someone", [.social: 1, .verbal: 0.3]),
            ("Sketch it out or picture it in your head", [.spatial: 1]),
            ("Just start trying things with your hands", [.handsOn: 0.7, .physical: 0.3]),
        ]),
        .choice("ch9", "Which job-for-a-day sounds the most fun?", [
            ("Film director", [.creative: 0.7, .leadership: 0.5]),
            ("Park ranger", [.nature: 1]),
            ("Personal trainer", [.physical: 1, .social: 0.3]),
            ("Sound engineer at a concert", [.musical: 1, .handsOn: 0.3]),
        ]),
        .choice("ch10", "Your friends would most likely ask you to…", [
            ("Settle a debate with the facts", [.analytical: 0.7, .verbal: 0.3]),
            ("Organise the group trip", [.leadership: 1]),
            ("Make the playlist", [.musical: 1]),
            ("Look after their pet or plants while they're away", [.nature: 1, .social: 0.3]),
        ]),
    ]
}
