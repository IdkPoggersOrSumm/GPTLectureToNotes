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
            I have a transcript of a lecture, and I want you to turn it into well-structured study notes in Obsidian Markdown format. Please let the first six words in your notes be a title. Please follow these formatting rules: Use '##' headers for each major topic. Use bullet points ('-') for key points, making sure to bold important terms using 'bold text'. Use tables for comparisons and structured information with clear columns and rows. Use blockquotes ('>') for definitions or important explanations. Use emojis in section headings where appropriate for better readability. Format mathematical equations in LaTeX by wrapping them in '$$'. Add a 'Note:' section for additional insights where needed. Please apply this formatting consistently while summarizing the lecture content into clear, concise study notes. Also, please do not include ```markdown or ``` and use nested bullet points. Also, please include a section of potential questions that could be asked on an exam, or otherwise questions that can be asked or further research for better clarity and dont exclude any details and be very comprehensive:\n
            """
        ),
        PromptOption(
            name: "Concise Summary",
            prompt: """
            Convert this lecture transcript into a concise summary with key points. Use Markdown formatting with headers, bullet points, and bold for important terms. Keep it brief but comprehensive:\n
            """
        ),
        
        PromptOption(
            name: "Lecture Progression Tracker",
            prompt: """
            I have a transcript of a lecture, and I want you to turn it into well-structured study notes in Obsidian Markdown format. Please let the first six words in your notes be a title. Please follow these formatting rules: Use '##' headers for each major topic. Use bullet points ('-') for key points, making sure to **bold important terms** using 'bold text'. Use tables for comparisons and structured information with clear columns and rows. Use blockquotes ('>') for definitions or important explanations. Use emojis in section headings where appropriate for better readability. Format mathematical equations in LaTeX by wrapping them in '$$'. Add a 'Note:' section for additional insights where needed. Please apply this formatting consistently while summarizing the lecture content into clear, concise study notes.

        In addition to standard notes, focus on tracking the **progression of ideas or conversation** as they unfold. Structure this progression as a sequence of labeled stages or sections. Identify shifts in topic, speaker, or emphasis and note **how** and **why** the conversation transitions. Use a structure like:

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

        **Overview Path:**  
        Topic 1 / Subtopic A / Subtopic B / Topic 2 / Topic 3

        This will help clarify the **narrative or logical flow** of the session. Do not exclude any tangents or backtracks—track them clearly. Be comprehensive and structured.
        
        Please also just start your notes with the title and dont end with 'end of notes'
        """
        )

    ]
}

struct PromptOption: Identifiable {
    let id = UUID()
    let name: String
    let prompt: String
}
