//
//  OpenAIPrompts.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 5/8/25.
//

import Foundation

struct PromptPresets {
    static let all: [PromptOption] = [
        PromptOption(
            name: "Standard Notes",
            prompt: """
            I have a transcript of a lecture, and I want you to turn it into well-structured study notes in Obsidian Markdown format. Please let the first six words in your notes be a title. Please follow these formatting rules: Use '##' headers for each major topic. Use bullet points ('-') for key points, making sure to bold important terms using 'bold text'. Use tables for comparisons and structured information with clear columns and rows. Use blockquotes ('>') for definitions or important explanations. Use emojis in section headings where appropriate for better readability. Format mathematical equations in LaTeX by wrapping them in '$$'. Add a 'Note:' section for additional insights where needed. Please apply this formatting consistently while summarizing the lecture content into clear, concise study notes. Also, please do not include ```markdown or ``` and use nested bullet points. Also, please include a section of potential questions that could be asked on an exam, or otherwise questions that can be asked or further research for better clarity and dont exclude any details and be very comprehensive. Please Note a key part to making good notes is to have nested bullets for your nested bullets to really nail the specificity. Also, some names or terms may be mis-interpreted in the transcription so please do your best to use context clues based on the entire topic and your current knowledge of the topic to correct the inconsistancies:\n
            """
        ),
        PromptOption(
            name: "500 Word Summary",
            prompt: """
                        I have a transcript of a lecture, and I want you to turn it into well-structured study notes in Obsidian Markdown format. Please let the first six words in your notes be a title. Please follow these formatting rules: Use '##' headers for each major topic. Use bullet points ('-') for key points, making sure to **bold important terms** using 'bold text'. Use tables for comparisons and structured information with clear columns and rows. Use blockquotes ('>') for definitions or important explanations. Use emojis in section headings where appropriate for better readability. Format ANY mathematical equations in LaTeX by wrapping them in '$$'. Add a 'Note:' section for additional insights where needed. Please apply this formatting consistently while summarizing the lecture content into clear, concise study notes.
                        If you are going to make a table, please make sure its not under a bullet point or indented.
                        In addition to standard notes, focus on tracking the **progression of ideas or conversation** as they unfold. Structure this progression as a sequence of labeled stages or sections. Identify shifts in topic, speaker, or emphasis and note **how** and **why** the conversation transitions. Also, some names or terms may be mis-interpreted in the transcription so please do your best to use context clues based on the entire topic and your current knowledge of the topic to correct the inconsistancies. Use a structure like:\n

                    ### 🧭 Progression Map

                    1. **Introduction of Topic A**  
                       - Summary of what was introduced and by whom  
                           - Key subpoints or reactions  
                                - What it led into  

                    2. **Transition to Topic B**  
                       - Trigger for transition (e.g. a question, comment, tangent)  
                           - Summary of this topic  
                                - Key shifts in tone or focus  

                    (...continue this way...)

                    End your output with a **hierarchical overview path** showing the lecture’s structure in a breadcrumb-style format. Example:
                    
                    Please Note a key part to making good notes is to have nested bullets for your nested bullets to really nail the specificity 
                    **Overview Path:**  
                    Topic 1 / Subtopic A / Subtopic B / Topic 2 / Topic 3

                    This will help clarify the **narrative or logical flow** of the session. Do not exclude any tangents or backtracks—track them clearly. Be comprehensive and structured.
                    
                    Please also just start your notes with the title and dont end with 'end of notes'
            
                    Please keep your notes 500 words ONLY:
            """
        ),
        
        PromptOption(
            name: "Lecture Progression Tracker",
            prompt: """
            I have a transcript of a lecture, and I want you to turn it into well-structured study notes in Obsidian Markdown format. Please let the first six words in your notes be a title. Please follow these formatting rules: Use '##' headers for each major topic. Use bullet points ('-') for key points, making sure to **bold important terms** using 'bold text'. Use tables for comparisons and structured information with clear columns and rows. Use blockquotes ('>') for definitions or important explanations. Use emojis in section headings where appropriate for better readability. Format mathematical equations in LaTeX by wrapping them in '$$'. Add a 'Note:' section for additional insights where needed. Please apply this formatting consistently while summarizing the lecture content into clear, concise study notes.
            If you are going to make a table, please make sure its not under a bullet point or indented.
            In addition to standard notes, focus on tracking the **progression of ideas or conversation** as they unfold. Structure this progression as a sequence of labeled stages or sections. Identify shifts in topic, speaker, or emphasis and note **how** and **why** the conversation transitions. Also, some names or terms may be mis-interpreted in the transcription so please do your best to use context clues based on the entire topic and your current knowledge of the topic to correct the inconsistancies. Use a structure like:

        ### 🧭 Progression Map

        1. **Introduction of Topic A**  
           - Summary of what was introduced and by whom  
               - Key subpoints or reactions  
                    - What it led into  

        2. **Transition to Topic B**  
           - Trigger for transition (e.g. a question, comment, tangent)  
               - Summary of this topic  
                    - Key shifts in tone or focus  

        (...continue this way...)

        End your output with a **hierarchical overview path** showing the lecture’s structure in a breadcrumb-style format. Example:
        
        Please Note a key part to making good notes is to have nested bullets for your nested bullets to really nail the specificity 
        **Overview Path:**  
        Topic 1 / Subtopic A / Subtopic B / Topic 2 / Topic 3

        This will help clarify the **narrative or logical flow** of the session. Do not exclude any tangents or backtracks—track them clearly. Be comprehensive and structured.
        
        Please also just start your notes with the title and dont end with 'end of notes'
        """
        ),
        PromptOption(
            name: "Flashcards",
            prompt: """
                I will provide you with a transcript from a lecture or video. Please extract the key concepts and facts from the transcript and format them into Quizlet flashcards. Each flashcard should have a Term, followed by a comma, then the Definition. Each term-definition pair should be on a new line. Focus on making the flashcards useful for studying: emphasize important definitions, processes, dates, people, vocabulary, and key takeaways.

                Format Example:
                Term 1,Definition 1
                Term 2,Definition 2
                Term 3,Definition 3

                Do not include any other text or commentary—just the flashcards in the format above.
                
                Here are details about good and bad flashcards
                1. One Question = One Answer
                Bad: "List all steps of cellular respiration." (Too broad)

                Good:

                Front: "What is the net ATP yield from glycolysis?"

                Back: 2 ATP

                Why? Isolating single facts forces focused retrieval and avoids cognitive overload.

                2. Use Cloze Deletion (Fill-in-the-Blank)
                Instead of:

                Front: "Define osmosis."

                Back: "The movement of water across a semipermeable membrane."

                Better:

                Front: "Osmosis is the movement of _____ across a _____ membrane."

                Back: "water; semipermeable"

                Why? Cloze cards mimic real-world test questions (e.g., short answer, MCQs).

                3. Ask Both Ways (Bidirectional)
                Example 1:

                Front: "What neurotransmitter is associated with pleasure/reward?"

                Back: Dopamine

                Example 2:

                Front: "Dopamine is associated with _____."

                Back: Pleasure/reward

                Why? Reinforces connections and prevents "cue dependency" (only recognizing info one way).

                4. Add Context, Not Just Definitions
                Bad:

                Front: "What is the Treaty of Versailles?"

                Back: "Peace treaty after WWI."

                Good:

                Front: "Why did the Treaty of Versailles contribute to WWII?"

                Back: "Harsh reparations on Germany led to economic collapse and resentment."

                Why? Understanding > rote memorization. Works for essays and critical-thinking exams.

                6. Break Down Complex Concepts
                Bad: "Explain how action potentials work."

                Good:

                Front: "At what voltage do Na+ channels open during an action potential?"

                Back: *-55 mV (threshold potential)*

                Front: "What causes the depolarization phase?"

                Back: Influx of Na+ ions

                Why? Chunking simplifies learning and links related ideas.

                7. Include Examples or Mnemonics
                Example:

                Front: "How to remember the order of taxonomy ranks?"

                Back: "King Philip Came Over For Good Soup" (Kingdom, Phylum, Class, Order, Family, Genus, Species)

                Why? Makes abstract info memorable.

                8. Avoid These Common Mistakes
                ❌ Too much text: Flashcards are not cheat sheets.
                ❌ Passive prompts:

                Bad: "The capital of France is _____." (Too easy)

                Better: "What European capital is known for the Eiffel Tower?"
                ❌ Ambiguous questions:

                Bad: "What is photosynthesis?"

                Better: "What are the inputs and outputs of photosynthesis?"

                Subject-Specific Tips
                STEM: Focus on formulas, steps, and relationships (e.g., "What’s the derivative of sin(x)?").

                History: Frame cards as cause/effect (e.g., "What event triggered the U.S. entry into WWII?").

                Languages: Include audio (via apps) for pronunciation.


                """)

    ]
}

struct PromptOption: Identifiable {
    let id = UUID()
    let name: String
    let prompt: String
}
