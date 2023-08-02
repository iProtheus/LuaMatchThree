--[[
    Match Three simple game
    - x and y are swapped to match debug presentation
    - AreCellsMatched can be extended to check for different types of matches
    Author: Aidar Kutluguzhin
    Date: 2023/08/02
]]
Board = {}
ToRemove = {}
BoardSizeX = 10
BoardSizeY = 10
AllowNonmatchingMoves = false

--helper functions

function AreCellsMatched(a, b, c)
    return a == b and b == c
end

function HasMatch(markToDelete)
    markToDelete = markToDelete or false
    local result = false
    for y = 1, BoardSizeY do
        for x = 1, BoardSizeX do
            if x > 1 and x < BoardSizeX and AreCellsMatched(Board[y][x-1], Board[y][x], Board[y][x+1]) then
                --print("Match at column "..y)
                result = true
                if markToDelete then
                    ToRemove[y][x-1] = true
                    ToRemove[y][x] = true
                    ToRemove[y][x+1] = true
                end
            end
            -- error-prone if the grid is not square
            if y > 1 and y < BoardSizeY and AreCellsMatched(Board[y-1][x], Board[y][x], Board[y+1][x]) then
                --print("Match at row "..x)
                result = true
                if markToDelete then
                    ToRemove[y-1][x] = true
                    ToRemove[y][x] = true
                    ToRemove[y+1][x] = true
                end
            end
        end
    end
    return result
end

function ShiftPieces(y,x)
    for i = x, 0, -1 do
        Board[y][i] = Board[y][i-1]
    end
    Board[y][1] = string.char(65 + math.random(0,5))
end

function IsMatchedAtPos(y,x)
    local result = false
    if y > 2                        then result = result or AreCellsMatched(Board[y-2][x],Board[y-1][x],Board[y][x]) end
    if y > 1 and y < BoardSizeY     then result = result or AreCellsMatched(Board[y-1][x],Board[y][x],Board[y+1][x]) end
    if           y < BoardSizeY - 1 then result = result or AreCellsMatched(Board[y][x],Board[y+1][x],Board[y+2][x]) end
    if x > 2                        then result = result or AreCellsMatched(Board[y][x-2],Board[y][x-1],Board[y][x]) end
    if x > 1 and x < BoardSizeX     then result = result or AreCellsMatched(Board[y][x-1],Board[y][x],Board[y][x+1]) end
    if           x < BoardSizeX - 1 then result = result or AreCellsMatched(Board[y][x],Board[y][x+1],Board[y][x+2]) end
    return result
end

function IsDeadlocked()
    local result = true
    for y = 1, BoardSizeY do
        for x = 1, BoardSizeX do
            if x < BoardSizeX then
                Board[y][x], Board[y][x+1] = Board[y][x+1], Board[y][x]
                if IsMatchedAtPos(y,x) or IsMatchedAtPos(y, x+1) then
                    result = false
                end
                Board[y][x], Board[y][x+1] = Board[y][x+1], Board[y][x]    
            end
            if y < BoardSizeY then
                Board[y][x], Board[y+1][x] = Board[y+1][x], Board[y][x]
                if IsMatchedAtPos(y,x) or IsMatchedAtPos(y+1, x) then
                    result = false
                end
                Board[y][x], Board[y+1][x] = Board[y+1][x], Board[y][x]    
            end
            
        end
    end
    return result
end

--main procedures

function Init()
    local counter = 0
    for y = 1, BoardSizeY do
        Board[y] = {}
        ToRemove[y] = {}
        for x = 1, BoardSizeX do
            Board[y][x] = string.char(65+counter%6)
            counter = counter + 1
            ToRemove[y][x] = false
        end
    end
    repeat
        Mix()
    until not HasMatch() and not IsDeadlocked()
end

function Tick()    
    for y = 1, BoardSizeY do
        for x = 1, BoardSizeX do
            if ToRemove[y][x] then
                ShiftPieces(y,x)
                ToRemove[y][x] = false
            end
        end
    end 
    Dump()   
end

function Move(x1,y1,x2,y2)
    Board[y1][x1], Board[y2][x2] = Board[y2][x2], Board[y1][x1]
    Tick()
end

function Mix()
    repeat
        for y = 1, BoardSizeY do
            for x = 1, BoardSizeX do
                j = math.random(x, BoardSizeX)
                Board[y][x], Board[y][j] = Board[y][j], Board[y][x]
            end
            j = math.random(y, BoardSizeY)
            Board[y], Board[j] = Board[j], Board[y]
        end
    until not HasMatch()
end

function Dump()
    io.write("    ")
    for x = 1, BoardSizeX do
        io.write(x)
    end
    print("")
    for y = 1, BoardSizeY do
        io.write(string.format("%02d",y).." |")
        for x = 1, BoardSizeX do
            io.write(Board[x][y])
        end
        print("| "..y)
    end
    io.write("    ")
    for x = 1, BoardSizeX do
        io.write(x)
    end
    print("")
end

--Main loop
Init()
Dump()
while true do
    local s = io.read() 
    if s:sub(1,1) ~= 'q' and s:sub(1,1) ~= 'm' then
        print("Invalid command. 'q' to exit, 'm x y d' to move where x and y are coordinates and d is 'u','d','l','r' for direction")
        Dump()
    elseif s == "q" then
        break
    elseif s:sub(1,1) == 'm' then
        local isValid = false
        local n, y1, x1, d = s:match("(%a) (%d+) (%d+) (%a)")
        x1 = tonumber(x1)
        y1 = tonumber(y1)
        local y2 = y1
        local x2 = x1
        if d == "l" then
            y2 = y2 - 1
        elseif d == "r" then
            y2 = y2 + 1
        elseif d == "u" then
            x2 = x2 - 1
        elseif d == "d" then
            x2 = x2 + 1
        else 
            isValid = false
        end
        if AllowNonmatchingMoves then
            Move(x1,y1,x2,y2)
        else
            if y1 > 0 and y2 > 0 and x1 > 0 and x2 > 0 and x1 <= BoardSizeX and x2 <= BoardSizeX and y1 <= BoardSizeY and y2 <= BoardSizeY then   
                Board[y1][x1], Board[y2][x2] = Board[y2][x2], Board[y1][x1]
                isValid = HasMatch()
                Board[y1][x1], Board[y2][x2] = Board[y2][x2], Board[y1][x1] 
            else
                isValid = false
            end
            if not isValid then
                print("Invalid move")
                Dump()
            else
                Move(x1,y1,x2,y2)
            end
        end
        while HasMatch(true) do
            Tick()  
        end
        if IsDeadlocked() then
            print("Found deadlock")
            repeat
                Mix()
            until not IsDeadlocked() and not HasMatch()
        end
    end
end
