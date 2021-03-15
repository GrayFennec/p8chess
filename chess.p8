pico-8 cartridge // http://www.pico-8.com
version 30
__lua__
--main code
--current coordinates of hover
hovr = 1
hovc = 1
--current selected coordinates
selr = nil
selc = nil
--whoevers turn it is
turn = 1
--number of players
nump = 2
--castling ability
cast = {}
--game board
gb = {}
--test board
tb = {}
--board size
brdw = 8
brdh = 8

--checks if a coordinate is valid
function val_coord(r,c)
	return r > 0 and c > 0 and r <= brdh and c <= brdw
end

--gets pnum of square
--if empty 0
--if invalid 3
--r,c: coordinate of square
--b: board being checked
function get_pnum(b,r,c)
	if val_coord(r,c) then
	 if b[r][c] != nil then
	 	return b[r][c].pnum
	 else
	 	return 0
	 end
	else
	 return 3
	end
end

function _update()
	--update hover
	update_hover()
	--update selec
	update_selec()
end

--player button input
function update_hover()
	if btnp(0) and hovc>1 then
		hovc = hovc-1
	end
	if btnp(1) and hovc<brdw then
		hovc = hovc+1
	end
	if btnp(2) and hovr>1 then
		hovr = hovr-1
	end
	if btnp(3) and hovr<brdh then
		hovr = hovr+1
	end
end

function update_selec()
	if btnp(4) then
	 if selr == nil and get_pnum(gb, hovr, hovc) == turn then
	  selr = hovr
	  selc = hovc
	  return
	 elseif selr != nil then
	  try_move(selr, selc, hovr, hovc)
	 end
	elseif not btnp(5) then
	 return
	end
	selr = nil
	selc = nil
end

--moves piece obj to destination
--if it is a valid move
--begr, begc: the beginning coordinates 
--desr, desc: the destination coordinates
function try_move(begr, begc, desr, desc)
 moves = legal_moves(begr,begc)
 --check if coords are legal move
	for move in all(moves) do
	 if move[1] == desr and move[2] == desc then
	  --move the piece
	  move_piece(gb, begr, begc, desr, desc)
	  --increment turn
	  turn = turn % nump + 1
	 end
	end
end

--moves a piece
--begr, begc: the beginning coordinates 
--desr, desc: the destination coordinates
--b: the board to make the move on
function move_piece(b, begr, begc, desr, desc)
 b[desr][desc] = gb[begr][begc]
 b[begr][begc] = nil
end
--updates value of incheck to show if current player is now in check
--b: the board to check for checks
--p: the player to check if in check
function update_check(b,p)
 --go through every piece
 for r=1,8 do
  for c=1,8 do
   if b[r][c] != nil and b[r][c].pnum != p then
   	moves = b[r][c].movl(b,r,c)
   	--check all moves
  		for move in all(moves) do
   		if is_king(b,move[1],move[2]) then
   	 	return true
   	 end
   	end
   end
  end
 end
 return false
end

function is_king(b,r,c)
 if b[r][c] != nil and b[r][c].sprnum == 10 then
  return true
 end
 return false
end

--gets all legal moves of piece
--r, c: the coordinates of the piece
function legal_moves(r,c)
			local moves = gb[r][c].movl(gb,r,c)
			for move in all(moves) do
			 --test move
			 make_tb()
			 move_piece(tb, r, c, move[1], move[2])
			 if update_check(tb, turn) then
			  del(moves, move)
			 end
			end
			return moves
end

--makes test board by cloning current game board
function make_tb()
	for r=1,8 do
		for c=1,8 do
		 tb[r][c] = gb[r][c]
		end
	end
end
-->8
--piece constructors

--abstract create new piece
--p=player
function new_piece(p)
	obj = {
		pnum = p
	}
 return obj
end

--creates a new pawn
function new_pawn(p)
	pawn = new_piece(p)
	pawn.sprnum = 0
	pawn.movl = function(b,r,c)
	 local moves = {}
	 local f = p == 1 and -1 or 1
	 --captures (bad and hacky)
	 if get_pnum(b,r+f,c-1) ^^ p == 3 then
	  add(moves,{r+f,c-1})
	 end
	 if get_pnum(b,r+f,c+1) ^^ p == 3 then
	  add(moves,{r+f,c+1})
	 end
	 --one row foward move
	 if get_pnum(b,r+f,c) == 0 then
	  add(moves,{r+f,c})
	  --two row foward move
	  if r-f == 1 or r-f == brdh then
	   f*=2
	   if get_pnum(b,r+f,c) == 0 then
	  	 add(moves,{r+f,c})
	   end
	  end
	 end
		return moves
	end
	return pawn
end

--creates a new knight
function new_knight(p)
	knight = new_piece(p)
	knight.sprnum = 2
	knight.movl = function(b,r,c)
		local moves = {}
	 --calculate values one and two away
		tup = r-2
		oup = r-1
		tdo = r+2
		odo = r+1
		tle = c-2
		ole = c-1
		tri = c+2
		ori = c+1
		--create possible moves
		local possi = {{tup, ole},{tup,ori},{oup,tle},{oup,tri},{odo,tle},{odo,tri},{tdo,ole},{tdo,ori}}
		for move in all(possi) do
		 local dnum = get_pnum(b,move[1], move[2])
		 if dnum != 3 and dnum != p then
		  add(moves, move)
		 end
		end
		return moves
	end
	return knight
end

--creates a new bishop
function new_bishop(p)
	bishop = new_piece(p)
	bishop.sprnum = 4
	bishop.movl = function(b,r,c)
	 local moves = {}
	 --table of diagonals
	 local direc = {{1, 1, true},{1, -1, true},{-1, -1, true},{-1, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along diagonals
	  for d in all(direc) do
	   if d[3] then
	    local dnum = get_pnum(b,r+i*d[1], c+i*d[2])
	    if dnum > 0 then
	     d[3] = false
	    end
	    if dnum != 3 and dnum != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	return bishop
end

--creates a new rook
function new_rook(p)
	rook = new_piece(p)
	rook.sprnum = 6
	rook.movl = function(b,r,c)
	 local moves = {}
	 --table of straights
	 local direc = {{1, 0, true},{0, -1, true},{-1, 0, true},{0, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along straights
	  for d in all(direc) do
	   if d[3] then
	    local dnum = get_pnum(b,r+i*d[1], c+i*d[2])
	    if dnum > 0 then
	     d[3] = false
	    end
	    if dnum != 3 and dnum != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	return rook
end

--creates a new queen
function new_queen(p)
	queen = new_piece(p)
	queen.sprnum = 8
	queen.movl = function(b,r,c)
	 local moves = {}
	 --table of 8 directions
	 local direc = {{1, 1, true},{1, 0, true},{1, -1, true},{0, -1, true},{-1, -1, true},{-1, 0, true},{-1, 1, true},{0, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along each direction
	  for d in all(direc) do
	   if d[3] then
	    local dnum = get_pnum(b,r+i*d[1], c+i*d[2])
	    if dnum > 0 then
	     d[3] = false
	    end
	    if dnum != 3 and dnum != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	return queen
end

--creates a new king
function new_king(p)
	king = new_piece(p)
	king.sprnum = 10
	king.movl = function(b,r,c)
	 local moves = {}
	 --calculate values one away
		oup = r-1
		odo = r+1
		ole = c-1
		ori = c+1
		local possi = {{oup, ole},{oup,ori},{r,ole},{r,ori},{odo,ole},{odo,ori},{odo,c},{oup,c}}
		for m in all(possi) do
			local dnum = get_pnum(b, m[1], m[2]) 
		 if dnum != 3 and dnum != p then
		  add(moves, m)
		 end
		end
		--check for castling
		--kingside
		if cast[turn].k and gb[r][6] == 0 and gb[r][7] == 0 then
			add(moves, {r, 7})
		end
		--queenside
		if cast[turn].q and gb[r][2] == 0 and gb[r][3] == 0 and gb[r][4] == 0 then
		 add(moves, {r, 3})
		end
		return moves
	end
	return king
end
-->8
--draw code
function _draw()
	draw_board()
	--draw moves of piece hovered over
	if selr != nil then
	 draw_selec()
	 draw_moves(selr,selc)
	end
	draw_every()
	draw_hover()
	--[[draw the current kingloc
	curloc = kingloc[turn]
	rectfill(curloc[2]*16-16, curloc[1]*16-16, curloc[2]*16-1, curloc[1]*16-1, 11)
 --]]
 print(tostr(update_check(gb,turn)),64,64)
end

--draws the board
function draw_board()
	pal(1, 15)
	pal(2, 4)
	for r=1,8 do
		for c=1,8 do
			--draw background square
			rectfill(c*16-16, r*16-16, c*16-1, r*16-1, (r+c)%2+1)
		end
	end
	pal()
end

--draws every piece
function draw_every()
	for r=1,8 do
		for c=1,8 do
			draw_piece(r,c)
		end
	end
end

--draws any location
function draw_piece(r,c)
 palt(14)
	if gb[r][c] != nil then
	 obj = gb[r][c]
	else
	 return
	end
	if(obj.pnum == 1) then
		pal(0, 7)
		pal(7, 0)
	end
	spr(obj.sprnum, c*16-16, r*16-16, 2, 2)
	pal()
end

--draws a piece's possible moves
function draw_moves(r,c)
 palt(14)
 if gb[r][c] != nil then
		moves = legal_moves(r,c)
		foreach(moves, draw_amove)
	end
end

--draws a single move
function draw_amove(move)
	r = move[1]
	c = move[2]
	--move to empty square
	if gb[r][c] == nil then
		spr(12, c*16-16, r*16-16, 2, 2)
 --capture
 else
  spr(14, c*16-16, r*16-16, 2, 2)
 	--rectfill(c*16-12, r*16-12, c*16-5, r*16-5, 11) 
 end
end

function draw_hover()
	rect(hovc*16-16, hovr*16-16, hovc*16-1, hovr*16-1, 12)
end

function draw_selec()
 rectfill(selc*16-16, selr*16-16, selc*16-1, selr*16-1, 11)
end
-->8
--init code
function _init()
	--init board to 8x8
	init_board(brdw,brdh)
	--create default chess board
	for c = 1,8 do
		gb[2][c] = new_pawn(2)
	 gb[7][c] = new_pawn(1)
	end
	gb[1][2] = new_knight(2)
	gb[1][7] = new_knight(2)
	gb[8][2] = new_knight(1)
	gb[8][7] = new_knight(1)
	gb[1][3] = new_bishop(2)
	gb[1][6] = new_bishop(2)
	gb[8][3] = new_bishop(1)
	gb[8][6] = new_bishop(1)
 gb[1][1] = new_rook(2)
 gb[1][8] = new_rook(2)
 gb[8][1] = new_rook(1)
 gb[8][8] = new_rook(1)
 gb[1][4] = new_queen(2)
 gb[8][4] = new_queen(1)
 gb[1][5] = new_king(2)
 gb[8][5] = new_king(1)
	kingloc = {{8, 5},{1, 5}}
	--allow each player to castle
	cast = {{k = true, q = true},{k = true, q=true}}
end

--initalizes empty nxm board
function init_board(n,m)
	for r=1,n do
		gb[r] = {}
		tb[r] = {}
		for c=1,m do
			gb[r][c] = nil
			tb[r][c] = nil
		end
	end
end
__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbbeeeeeeeebbbb
eeeeee7777eeeeeeeeeee7ee7eeeeeeeeeeeeee77eeeeeeeeee77e7ee7e77eeeee7ee7eeee7ee7eeeeeeeee77eeeeeeeeeeeeeeeeeeeeeeebbbeeeeeeeeeebbb
eeeee700007eeeeeeeee707707eeeeeeeeeeee7007eeeeeeeee7070770707eeee707707ee707707eeeeeee7777eeeeeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeebb
eeee70000007eeeeeeee7000007eeeeeeeeee700007eeeeeeee7000000007eeeee707707707707eeeeeeeee77eeeeeeeeeeeeeeeeeeeeeeebeeeeeeeeeeeeeeb
eeee70000007eeeeeee70000007eeeeeeeeee700007eeeeeeee7000000007eeeee707707707707eeeee777e77e777eeeeeeeeebbbbeeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeee707000007eeeeeeee70077007eeeeeeee70777707eeeeee700707707007eeee700077770007eeeeeeebbbbbbeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeee7000000007eeeeeeee70077007eeeeeeee70000007eeeeeee7070000707eeee70000777700007eeeeebbbbbbbbeeeeeeeeeeeeeeeeeeee
eeeee700007eeeeeee7000700007eeeeeeeee700007eeeeeeeeee700007eeeeeeee7000000007eeee70000077000007eeeeebbbbbbbbeeeeeeeeeeeeeeeeeeee
eeeeee7007eeeeeeee70070000007eeeeeeeee7007eeeeeeeeeee700007eeeeeeee7000000007eeee70000077000007eeeeebbbbbbbbeeeeeeeeeeeeeeeeeeee
eeeee700007eeeeeeee7770000007eeeeeeee700007eeeeeeeeee700007eeeeeeeee70000007eeeeee700007700007eeeeeebbbbbbbbeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeeeee70000007eeeeeee70077007eeeeeeee70000007eeeeeeee70777707eeeeeee7777777777eeeeeeeebbbbbbeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeeee700000007eeeeeee77000077eeeeeeee70777707eeeeeee7000000007eeeeee7000770007eeeeeeeeebbbbeeeeeeeeeeeeeeeeeeeeee
eee7000000007eeeeee70000000007eeeee7000000007eeeeee7000000007eeeeee7077777707eeeeee7700770077eeeeeeeeeeeeeeeeeeebeeeeeeeeeeeeeeb
eee7000000007eeeeee70000000007eeee700000000007eeeee7000000007eeeeee7000000007eeeeeee70077007eeeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeebb
eee7777777777eeeeee77777777777eeee777777777777eeeee7777777777eeeeee7777777777eeeeeee77777777eeeeeeeeeeeeeeeeeeeebbbeeeeeeeeeebbb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbbeeeeeeeebbbb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000
