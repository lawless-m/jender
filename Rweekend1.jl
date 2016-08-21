#=
C++ version hosted at http://goo.gl/9yItEO http://goo.gl/sBih70

=#

unshift!(LOAD_PATH, ".")

using Vecs: RGB, zero, Vec3, unitVector
using Entities: World, Entity, Sphere, hitWorld, hitEntity!
using Materials: Lambertian, Metal, Dielectric
using Rays: Ray, pointAt
using Cameras: Camera, shoot

function addcolor!(sample::RGB, r::Ray, depth::Int)
	h = hitWorld(WORLD, r, 0.001, Inf)
	if h == nothing
		y = unitVector(r.direction).y
		sample.r += 0.75 - 0.25y
		sample.g += 0.85 - 0.15y
		sample.b += 1.0
	elseif depth < 50
		onscreen, scattered, attenuation = Materials.scatter(h.material, r, h)
		if onscreen
			addcolor!(sample, scattered, depth+1)
			sample.r *= attenuation[1]
			sample.g *= attenuation[2]
			sample.b *= attenuation[3]
		end
	end
end

function push_random_entities!(entities::Vector{Entity})
	for a in -11:10
		for b in -11:10
			choose_mat = rand()
			center = Vec3(a + 0.9rand(), 0.2, b + 0.9rand())
			if length(center - Vec3(4.0, 0.2, 0.0)) > 0.9
				if choose_mat < 0.8
					push!(entities, Sphere(center, 0.2, Lambertian(rand()*rand(), rand()*rand(), rand()*rand())))
				elseif choose_mat < 0.95
					push!(entities, Sphere(center, 0.2, Metal(0.5(1+rand()), 0.5(1+rand()), 0.5(1+rand()), 0.5rand())))
				else
					push!(entities, Sphere(center, 0.2, Dielectric(1.5)))
				end
			end
		end
	end
end


entities = Entity[
			Sphere(0,-1000,0, 1000, Lambertian(0.5, 0.5, 0.5))
			, Sphere(0, 1, 0, 1.0, Dielectric(1.5))
			, Sphere(-4, 1, 0, 1.0, Lambertian(0.4, 0.2, 0.1))
			, Sphere(4, 1, 0, 1.0, Metal(0.7, 0.6, 0.5, 0.0))
		]

println("Build world")
push_random_entities!(entities)

const WIDTH = 1200
const HEIGHT = 800
const SAMPLES = 10
const WORLD = World(entities, [Camera(Vec3(13,2,3), Vec3(0,0,0), Vec3(0,1,0), 20.0, 3/2, 0.1, 10.0)])

function render(cols::Matrix{Vec3}, numsamples::Int)
	rgb = RGB()
	for j in size(cols)[1]:-1:1 # makes the next line be a countdown rather than up
		println("Row $j")
		for i in 1:size(cols)[2]
			zero(rgb)
			for k in 1:numsamples
				addcolor!(rgb, shoot(WORLD.cameras[1], (i-1 + rand()) / size(cols)[2], (j-1 + rand()) / size(cols)[1]), 0)
			end
			cols[j,i] = Vec3(rgb)
		end
	end
end

function writepgm(cols::Matrix, filename, scale::Float64)
	f(v) = floor(Int,255.99*sqrt(v*scale))
	pgm = open("$filename.pgm", "w")
	write(pgm, "P3\n$(size(cols)[2]) $(size(cols)[1]) 255\n")
	for j in size(cols)[1]:-1:1
		for i in 1:size(cols)[2]
			write(pgm, "$(f(cols[j,i].x)) $(f(cols[j,i].y)) $(f(cols[j,i].z)) ")
		end
		write(pgm, "\n")
		
	end
	close(pgm)
end

if true 
	cols = Matrix{Vec3}(2*400, 3*400) # height, width
	@time render(cols, SAMPLES)
	writepgm(cols, "Weekend1", 1/SAMPLES)
else 
	srand(0)
	if false 
		cols = Matrix{Vec3}(2*100, 3*100) # height, width
		c = RGB()
		addcolor!(c, shoot(WORLD.cameras[1], 50.5/size(cols)[2], 60.5/size(cols)[1]), 0)
		@profile render(cols, 1/3)
		Profile.print()
	else	
		cols = Matrix{Vec3}(2*200, 3*200) # height, width
		c = RGB()
		@time addcolor!(c, shoot(WORLD.cameras[1], 50.5/size(cols)[2], 60.5/size(cols)[1]), 0)
		@time render(cols, 3)
		# 90.326774 seconds (1.86 G allocations: 69.478 GB, 8.73% gc time)
	end
	writepgm(cols, "Profiled", 1/3)
end

