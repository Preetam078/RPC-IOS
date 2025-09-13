//
//  ContentView.swift
//  rockPaperScissor
//
//  Created by Preetam Mondal on 13/09/25.
//

import SwiftUI

protocol GameChoice {
    var title: String { get }
    var emoji: String { get }
}

struct Rock: GameChoice {
    let title = "Rock"
    let emoji = "✊"
}

struct Paper: GameChoice {
    let title = "Paper"
    let emoji = "✋"
}

struct Scissors: GameChoice {
    let title = "Scissors"
    let emoji = "✌️"
}


struct ResetButtonModifier: ViewModifier {
    var isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                       .foregroundColor(isDisabled ? .red : .green) // text color logic
                       .frame(maxWidth: .infinity)
                       .padding(.vertical, 14)
                       .background(
                           RoundedRectangle(cornerRadius: 12)
                               .fill(Color(red: 51/255, green: 65/255, blue: 85/255)
                                   .opacity(isDisabled ? 0.3 : 0.6)) // bg lighter when disabled
                       )
                       .opacity(isDisabled ? 0.6 : 1.0)
    }
}

extension View {
    func resetButtonStyle(isDisabled: Bool) -> some View {
            self.modifier(ResetButtonModifier(isDisabled: isDisabled))
    }
}

struct ContentView: View {
    
    @State private var currentRound: Int = 1
    @State private var playerScore: Int = 0
    @State private var computerScore: Int = 0
    @State private var winner: String?
    @State private var playerChoice: GameChoice? = nil
    @State private var computerChoice: GameChoice? = nil
    @State private var showGameOver: Bool = false
    
    let choices: [GameChoice] = [Rock(), Paper(), Scissors()]
    
    func handleResetButtonClick() {
       playerScore = 0
       computerScore = 0
       currentRound = 1
       winner = nil
       playerChoice = nil
       computerChoice = nil
    }
    
    func checkWinner() {
        guard let player = playerChoice, let computer = computerChoice else { return }
        
        if player.title == computer.title {
            // Draw
            winner = "Draw"
        } else if (player is Rock && computer is Scissors) ||
                  (player is Paper && computer is Rock) ||
                  (player is Scissors && computer is Paper) {
            // Player wins
            playerScore += 1
            winner = "Player"
        } else {
            // Computer wins
            computerScore += 1
            winner = "Computer"
        }
        
        // Increment round until 5
        if currentRound < 5 {
            currentRound += 1
        } else {
            showGameOver = true
        }
    }

    
    func playCurrentRound(chosenOption: GameChoice) async {
        await MainActor.run {
            playerChoice = chosenOption
            computerChoice = nil
        }
        
        // shuffle 20 times, every 0.1s
        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run {
                computerChoice = choices.randomElement()
            }
        }
        
        // final choice lock
        await MainActor.run {
            computerChoice = choices.randomElement()
        }
        
        checkWinner()
    }


    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 17/255, green: 26/255, blue: 34/255),
                    Color(red: 13/255, green: 17/255, blue: 23/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack {
                VStack(spacing: 20) {
                    Text("Rock Paper Scissors")
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    
                    Text("Round \(currentRound) of 5")
                        .foregroundColor(Color.white.opacity(0.7))
                        .fontWeight(.bold)
                        .padding(.top, 8)
                    
                    HStack(spacing: 20) {
                        ForEach (choices, id: \.self.title) { choice in
                            self.choiceTile(currentOption:choice)
                        }
                    }
                    .padding(.top, 20)
                    HStack {
                        chosenTile(title: "Your choice", choice: playerChoice)
                        chosenTile(title: "Computer's choice", choice: computerChoice)
                    }
                    .padding(.top, 20)

                    scoreTile()
                    resetButton()
                    
                }
            }
        }
        .alert("Game Over", isPresented: $showGameOver) {
                    Button("Play Again", action: handleResetButtonClick)
                } message: {
                    if playerScore > computerScore {
                        Text("🎉 You Win! Final Score: \(playerScore) - \(computerScore)")
                    } else if computerScore > playerScore {
                        Text("🤖 Computer Wins! Final Score: \(playerScore) - \(computerScore)")
                    } else {
                        Text("🤝 It's a Draw! Final Score: \(playerScore) - \(computerScore)")
                    }
                }
    }
    
    // Reusable tile component
    private func choiceTile(currentOption: GameChoice) -> some View {
        Button(action: {
            Task {
                await playCurrentRound(chosenOption: currentOption)
            }
        }) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 15/255, green: 26/255, blue: 34/255),
                            Color(red: 13/255, green: 17/255, blue: 23/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Text(currentOption.emoji)
                            .font(.system(size: 40))
                        Text(currentOption.title)
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                )
        }
        .buttonStyle(PlainButtonStyle()) // 👈 remove button highlight glow
    }


    
    private func chosenTile(title: String, choice: GameChoice?) -> some View {
        VStack {
            Text(title)
                .foregroundColor(Color.white.opacity(0.7))
            
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 15/255, green: 26/255, blue: 34/255),
                            Color(red: 13/255, green: 17/255, blue: 23/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 170, height: 220)
                .cornerRadius(30)
                .shadow(radius: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(red: 15/255, green: 26/255, blue: 34/255), lineWidth: 6)
                )
                .overlay(
                    VStack(spacing: 8) {
                        if let safeChoice = choice {
                            Text(safeChoice.emoji)
                                .font(.system(size: 70))
                            Text(safeChoice.title)
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                                .fontWeight(.bold)
                                .fontDesign(.monospaced)
                        } else {
                            Text("N/A")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 50, weight: .bold, design: .monospaced))
                        }
                    }
                )
        }
    }

    private func scoreTile() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(red: 30/255, green: 41/255, blue: 59/255).opacity(0.5))
            .frame(width: 350, height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 51/255, green: 65/255, blue: 85/255), lineWidth: 1)
            )
            .overlay(
                VStack(spacing: 10) {
                    Text("Score")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("\(playerScore) - \(computerScore)")
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            )
            .padding(.top, 20)
    }
    
    private func resetButton() -> some View {
        Button(action: {
            handleResetButtonClick()
        }) {
            Text("Reset Score")
                .resetButtonStyle(isDisabled: currentRound == 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
}

#Preview {
    ContentView()
}
