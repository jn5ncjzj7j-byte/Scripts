// ==UserScript==
// @name         Chess.com Move Helper
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Basic userscript skeleton to read board state and interact with Chess.com DOM
// @author       You
// @match        https://www.chess.com/play/*
// @match        https://www.chess.com/game/*
// @grant        none
// ====/UserScript==

(function() {
    'use strict';

    // Wait for the chess board to load in the DOM
    function initScript() {
        console.log("Chess.com Helper loaded!");
        
        // Create a floating UI panel
        const panel = document.createElement('div');
        panel.innerHTML = `
            <div id="custom-chess-panel" style="position: fixed; top: 80px; right: 20px; z-index: 9999; background: #262421; color: #fff; padding: 15px; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.5); font-family: sans-serif;">
                <h3 style="margin: 0 0 10px 0; font-size: 16px;">Chess Assistant</h3>
                <button id="read-board-btn" style="background: #81b64c; color: white; border: none; padding: 8px 12px; border-radius: 4px; cursor: pointer;">Read Board State</button>
            </div>
        `;
        document.body.appendChild(panel);

        document.getElementById('read-board-btn').addEventListener('click', () => {
            readChessBoard();
        });
    }

    // Function to read piece positions from Chess.com DOM classes
    function readChessBoard() {
        // Chess.com pieces are typically rendered inside elements with classes like 'piece square-34'
        const pieces = document.querySelectorAll('#board-game-board .piece, wc-chess-board .piece');
        
        if (pieces.length === 0) {
            alert("Board not found! Make sure you are actively in a game.");
            return;
        }

        let pieceData = [];
        pieces.forEach(piece => {
            // Class names contain the piece type (e.g., 'wp' for white pawn, 'bk' for black king) and position (e.g., 'square-34')
            const classList = Array.from(piece.classList);
            const pieceType = classList.find(c => c.length === 2 && /^[wb][prnbqk]$/.test(c));
            const squarePos = classList.find(c => c.startsWith('square-'));
            
            if (pieceType && squarePos) {
                pieceData.push({ piece: pieceType, square: squarePos.replace('square-', '') });
            }
        });

        console.log("Detected Pieces:", pieceData);
        alert(`Detected ${pieceData.length} pieces on the board. Check console for details.`);
    }

    // Automatically initialize after page loads
    window.addEventListener('load', () => {
        setTimeout(initScript, 3000); // Wait for React/Angular components to render
    });

})();
