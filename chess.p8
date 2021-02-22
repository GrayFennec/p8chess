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
--current selected piece
selp = 0
--current tick 0 to 15
t = 0
--whoevers turn it is
turn = 1
--number of players
nump = 2
--castling ability
cast = {}
--is player in check
incheck = {}
--keep track of king locations
kingloc = {}
--list of all game pieces
pl = {}
--value of the last deleted piece
lastd = nil
--game board
gb = {}
--board size
brdw = 8
brdh = 8

function _init()
	--init board to 8x8
	init_board(brdw,brdh)
	--create default chess board
	for c = 1,8 do
	 new_pawn(2,c,2)
	 new_pawn(7,c,1)
	end
	new_knight(1,2,2)
	new_knight(1,7,2)
	new_knight(8,2,1)
	new_knight(8,7,1)
	new_bishop(1,3,2)
	new_bishop(1,6,2)
	new_bishop(8,3,1)
	new_bishop(8,6,1)
	new_rook(1,1,2)
	new_rook(1,8,2)
	new_rook(8,1,1)
	new_rook(8,8,1)
	new_queen(1,4,2)
	new_queen(8,4,1)
	new_king(1,5,2)
	new_king(8,5,1)
	kingloc = {{8, 5},{1, 5}}
	--allow each player to castle
	cast = {{k = true, q = true},{k = true, q=true}}
 --both players start not in check
 incheck = {false, false}
end

--initalizes empty nxm board
function init_board(n,m)
	for r=1,n do
		gb[r] = {}
		for c=1,m do
			gb[r][c] = 0
		end
	end
end

--checks if a coordinate is valid
function val_cord(r,c)
	return r > 0 and c > 0 and r <= brdh and c <= brdw
end

--gets pnum of square
--it square empty, pnum is 0
function get_pnum(r,c)
	if val_cord(r,c) and gb[r][c] != 0 then
	 return pl[gb[r][c]].pnum
	else
	 return 0
	end
end

function _update()
	--increment tick
	t = (t+1)%16
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
	 if selp == 0 and get_pnum(hovr, hovc) == turn then
	  selp = gb[hovr][hovc]
	  if selp > 0 then
	   selr = hovr
	   selc = hovc
	  end
	  return
	 elseif selp != 0 then
	  move_piece(selp, hovr, hovc)
	 end
	elseif not btnp(5) then
	 return
	end
	selp = 0
	selr = nil
	selc = nil
end

--moves piece obj to destination
--if it is a valid move
function move_piece(p, desr, desc)
 obj = pl[p]
 moves = obj.legmov(obj)
 --check if coords are legal move
	for move in all(moves) do
	 if move[1] == desr and move[2] == desc then
	  curcast = cast[turn]
	  --check if king was moved
	  if obj.sprnum == 10 then
	   --check if move was castle
	   if obj.col == 5 then
	    iscast = false
	    --kingside
	    if desc == 7 then
	     rookloc = 8
	     rookdes = 6
	     iscast = true
	    end
	    --queenside
	    if desc == 3 then
	     rookloc = 1
	     rookdes = 4
	     iscast = true
	    end 
	    if iscast then
	     --move rook
	     rookp = gb[desr][rookloc]
		    gb[desr][rookdes] = rookp
		    gb[desr][rookloc] = 0
		    pl[rookp].col = rookdes	
		   end
	   end
	   --can no longer castle
	   cast[turn].k = false
	   cast[turn].q = false
	   --update king location
	   kingloc[turn][1] = desr
	   kingloc[turn][2] = desc
	  end
	  --check if rook on edge is moved
	  if obj.sprnum == 6 and obj.row == turn * -7 + 15 then
	  	--check if castle is invalidated
	  	if curcast.k and obj.col == 8 then
	   	cast[turn].k = false
	  	end
	  	if curcast.q and obj.col == 1 then
	    cast[turn].q = false
	   end
	  end
	  --move the piece
	  gb[obj.row][obj.col] = 0
	  --delete piece that is there
	  if gb[desr][desc] > 0 then
	   lastd = del(pl, pl[gb[desr][desc]])
	  end
	  gb[desr][desc] = p
	  obj.row = desr
	  obj.col = desc
	  --increment turn
	  turn = turn % nump + 1
	  return
	 end
	end
end

--updates value of incheck to show if current player is now in check
function update_check()
 for obj in all(pl) do
  if obj.pnum != turn then
   for move in obj.legmov(obj) do
   	if move == kingloc[turn] then
   	 return true
   	end
   end
  end
 end
 return false
end


-->8
--piece constructors

--abstract create new piece
--r=row c=col p=player
function new_piece(r,c,p)
	obj = {
		row = r,
		col = c,
		pnum = p,
		legmov = function(this)
		 local moves = this.movl(this)
   for move in all(moves) do
    --remove out of bounds moves
    if move[1] < 1 or move[1] > brdh then
     del(moves, move)
    elseif move[2] < 1 or move[2] > brdw then
     del(moves, move)
    else
					--remove moves which lead to check
					    
      
    end
   end
   return moves
  end
	}
 return obj
end

--adds piece to piece list
function add_piece(obj,r,c)
	pl[#pl+1] = obj
	--add pointer on game board
	gb[r][c] = #pl	
end

--creates a new pawn
function new_pawn(r,c,p)
	pawn = new_piece(r,c,p)
	pawn.sprnum = 0
	pawn.movl = function(this)
	 local r = this.row
	 local c = this.col
	 local moves = {}
	 local f = p == 1 and -1 or 1
	 --captures (bad and hacky)
	 if get_pnum(r+f,c-1) ^^ p == 3 then
	  add(moves,{r+f,c-1})
	 end
	 if get_pnum(r+f,c+1) ^^ p == 3 then
	  add(moves,{r+f,c+1})
	 end
	 --one row foward move
	 if get_pnum(r+f,c) == 0 then
	  add(moves,{r+f,c})
	  --two row foward move
	  if r-f == 1 or r-f == brdh then
	   f*=2
	   if get_pnum(r+f,c) == 0 then
	  	 add(moves,{r+f,c})
	   end
	  end
	 end
		return moves
	end
	add_piece(pawn,r,c)
end

--creates a new knight
function new_knight(r,c,p)
	knight = new_piece(r,c,p)
	knight.sprnum = 2
	knight.movl = function(this)
		local r = this.row
	 local c = this.col
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
		for m in all(possi) do
		 if get_pnum(m[1], m[2]) != p then
		  add(moves, m)
		 end
		end
		return moves
	end
	add_piece(knight,r,c)
end

--creates a new bishop
function new_bishop(r,c,p)
	bishop = new_piece(r,c,p)
	bishop.sprnum = 4
	bishop.movl = function(this)
	 local r = this.row
	 local c = this.col
	 local moves = {}
	 --table of diagonals
	 local direc = {{1, 1, true},{1, -1, true},{-1, -1, true},{-1, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along diagonals
	  for d in all(direc) do
	   if d[3] then
	    s = get_pnum(r+i*d[1], c+i*d[2])
	    if s > 0 then
	     d[3] = false
	    end
	    if s != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	add_piece(bishop,r,c)
end

--creates a new rook
function new_rook(r,c,p)
	rook = new_piece(r,c,p)
	rook.sprnum = 6
	rook.movl = function(this)
		local r = this.row
	 local c = this.col
	 local moves = {}
	 --table of straights
	 local direc = {{1, 0, true},{0, -1, true},{-1, 0, true},{0, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along straights
	  for d in all(direc) do
	   if d[3] then
	    s = get_pnum(r+i*d[1], c+i*d[2])
	    if s > 0 then
	     d[3] = false
	    end
	    if s != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	add_piece(rook,r,c)
end

--creates a new queen
function new_queen(r,c,p)
	queen = new_piece(r,c,p)
	queen.sprnum = 8
	queen.movl = function(this)
		local r = this.row
	 local c = this.col
	 local moves = {}
	 --table of 8 directions
	 local direc = {{1, 1, true},{1, 0, true},{1, -1, true},{0, -1, true},{-1, -1, true},{-1, 0, true},{-1, 1, true},{0, 1, true}}
	 for i = 1,max(brdw,brdh) do
	  --add moves along each direction
	  for d in all(direc) do
	   if d[3] then
	    s = get_pnum(r+i*d[1], c+i*d[2])
	    if s > 0 then
	     d[3] = false
	    end
	    if s != p then
	     add(moves,{r+i*d[1],c+i*d[2]})
	    end
	   end
   end
	 end
		return moves
	end
	add_piece(queen,r,c)
end

--creates a new king
function new_king(r,c,p)
	king = new_piece(r,c,p)
	king.sprnum = 10
	king.movl = function(this)
		local r = this.row
	 local c = this.col
	 local moves = {}
	 --calculate values one away
		oup = r-1
		odo = r+1
		ole = c-1
		ori = c+1
		local possi = {{oup, ole},{oup,ori},{r,ole},{r,ori},{odo,ole},{odo,ori},{odo,c},{oup,c}}
		for m in all(possi) do
		 if get_pnum(m[1], m[2]) != p then
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
	add_piece(king,r,c)
end
-->8
--draw code
function _draw()
	draw_board()
	--draw moves of piece hovered over
	if selp > 0 then
	 draw_selec()
	 draw_moves(pl[selp])
	end
	draw_every()
	draw_hover()
	--[[draw the current kingloc
	curloc = kingloc[turn]
	rectfill(curloc[2]*16-16, curloc[1]*16-16, curloc[2]*16-1, curloc[1]*16-1, 11)
 --]]
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
	foreach(pl, draw_piece)
end

--draws any given piece
function draw_piece(obj)
	palt(14)
	if(obj.pnum == 1) then
		pal(0, 7)
		pal(7, 0)
	end
	spr(obj.sprnum, obj.col*16-16, obj.row*16-16, 2, 2)
	pal()
end

--draws a piece's possible moves
function draw_moves(obj)
	moves = obj.legmov(obj)
	foreach(moves, draw_amove)
end

--draws a single move
function draw_amove(move)
	r = move[1]
	c = move[2]
	rectfill(c*16-12, r*16-12, c*16-5, r*16-5, 11)
end

function draw_hover()
 --if(t<8) then
		rect(hovc*16-16, hovr*16-16, hovc*16-1, hovr*16-1, 12)
	--end
end

function draw_selec()
 rectfill(selc*16-16, selr*16-16, selc*16-1, selr*16-1, 11)
end
__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee7777eeeeeeeeeee7ee7eeeeeeeeeeeeee77eeeeeeeeee77e7ee7e77eeeee7ee7eeee7ee7eeeeeeeee77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeee700007eeeeeeeee707707eeeeeeeeeeee7007eeeeeeeee7070770707eeee707707ee707707eeeeeee7777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeeee7000007eeeeeeeeee700007eeeeeeee7000000007eeeee707707707707eeeeeeeee77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeee70000007eeeeeeeeee700007eeeeeeee7000000007eeeee707707707707eeeee777e77e777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeee707000007eeeeeeee70077007eeeeeeee70777707eeeeee700707707007eeee700077770007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeee7000000007eeeeeeee70077007eeeeeeee70000007eeeeeee7070000707eeee70000777700007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeee700007eeeeeee7000700007eeeeeeeee700007eeeeeeeeee700007eeeeeeee7000000007eeee70000077000007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee7007eeeeeeee70070000007eeeeeeeee7007eeeeeeeeeee700007eeeeeeee7000000007eeee70000077000007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeee700007eeeeeeee7770000007eeeeeeee700007eeeeeeeeee700007eeeeeeeee70000007eeeeee700007700007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeeeee70000007eeeeeee70077007eeeeeeee70000007eeeeeeee70777707eeeeeee7777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee70000007eeeeeeee700000007eeeeeee77000077eeeeeeee70777707eeeeeee7000000007eeeeee7000770007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee7000000007eeeeee70000000007eeeee7000000007eeeeee7000000007eeeeee7077777707eeeeee7700770077eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee7000000007eeeeee70000000007eeee700000000007eeeee7000000007eeeeee7000000007eeeeeee70077007eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee7777777777eeeeee77777777777eeee777777777777eeeee7777777777eeeeee7777777777eeeeeee77777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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
