require 'spec_helper'

describe OA::Graph do

  let(:g1) { OA::Graph.new RDF::Graph.new.from_ttl("
    <http://my.identifiers.com/oa_comment> a <http://www.w3.org/ns/oa#Annotation>;
       <http://www.w3.org/ns/oa#hasBody> [
         a <http://www.w3.org/2011/content#ContentAsText>,
           <http://purl.org/dc/dcmitype/Text>;
         <http://www.w3.org/2011/content#chars> \"I love this!\"
       ];
       <http://www.w3.org/ns/oa#hasTarget> <http://purl.stanford.edu/kq131cs7229>;
       <http://www.w3.org/ns/oa#motivatedBy> <http://www.w3.org/ns/oa#commenting> . ") }
  let(:g2) { OA::Graph.new RDF::Graph.new.from_jsonld(
    '{
        "@context": "http://www.w3.org/ns/oa-context-20130208.json",
        "@id": "http://my.identifiers.com/oa_bookmark",
        "@type": "oa:Annotation",
        "motivatedBy": "oa:bookmarking",
        "hasTarget": "http://purl.stanford.edu/kq131cs7229"
      }' ) }
  let(:g3) { OA::Graph.new RDF::Graph.new.from_jsonld(
    '{
        "@context": "http://www.w3.org/ns/oa-context-20130208.json",
        "@id": "http://example.org/annos/annotation/mult-targets.json",
        "@type": "oa:Annotation",
        "motivatedBy": "oa:commenting",
        "hasBody": {
          "@type": [
            "cnt:ContentAsText",
            "dctypes:Text"
          ],
          "chars": "I love these two things!"
        },
        "hasTarget": [
          "http://purl.stanford.edu/kq131cs7229",
          "https://stacks.stanford.edu/image/kq131cs7229/kq131cs7229_05_0032_large.jpg"
        ]
      }' ) }

  context 'jsonld flavors' do
    context '#jsonld_oa' do
      it 'has context as url' do
        expect(g1.jsonld_oa).to match /"@context":\s*"http:\/\/www.w3.org\/ns\/oa-context-20130208.json"/
        expect(g2.jsonld_oa).to match /"@context":\s*"http:\/\/www.w3.org\/ns\/oa-context-20130208.json"/
      end
      it 'parses as graph' do
        new_g = OA::Graph.new RDF::Graph.new.from_jsonld g1.jsonld_oa
        expect(new_g.to_ttl).to eq g1.to_ttl
        new_g = OA::Graph.new RDF::Graph.new.from_jsonld g2.jsonld_oa
        expect(new_g.to_ttl).to eq g2.to_ttl
      end
    end
    context '#jsonld_iiif' do
      it 'has context as url' do
        expect(g1.jsonld_iiif).to match /"@context":\s*"http:\/\/iiif.io\/api\/presentation\/2\/context.json"/
        expect(g2.jsonld_iiif).to match /"@context":\s*"http:\/\/iiif.io\/api\/presentation\/2\/context.json"/
      end
      it 'parses as graph' do
        new_g = OA::Graph.new RDF::Graph.new.from_jsonld g1.jsonld_iiif
        expect(new_g.to_ttl).to eq g1.to_ttl
        new_g = OA::Graph.new RDF::Graph.new.from_jsonld g2.jsonld_iiif
        expect(new_g.to_ttl).to eq g2.to_ttl
      end
    end
  end

  context 'canned query methods' do
    it '#id_as_url' do
      expect(g1.id_as_url).to eql 'http://my.identifiers.com/oa_comment'
      expect(g2.id_as_url).to eql 'http://my.identifiers.com/oa_bookmark'
      expect(g3.id_as_url).to eql 'http://example.org/annos/annotation/mult-targets.json'
    end
    context '#motivated_by' do
      it 'single' do
        expect(g1.motivated_by).to eq ['http://www.w3.org/ns/oa#commenting']
        expect(g2.motivated_by).to eq ['http://www.w3.org/ns/oa#bookmarking']
        expect(g3.motivated_by).to eq ['http://www.w3.org/ns/oa#commenting']
      end
      it 'multiple' do
        g = OA::Graph.new RDF::Graph.new.from_jsonld(
          '{
              "@context": "http://www.w3.org/ns/oa-context-20130208.json",
              "@id": "http://example.org/annos/annotation/mult-motivations.json",
              "@type": "oa:Annotation",
              "motivatedBy": [
                "oa:moderating",
                "oa:tagging"
              ],
              "hasBody": {
                "@id": "http://dbpedia.org/resource/Banhammer",
                "@type": "oa:SemanticTag"
              },
              "hasTarget": "http://purl.stanford.edu/kq131cs7229"
            }' )
        gm = g.motivated_by
        expect(gm.size).to eql 2
        expect(gm).to include('http://www.w3.org/ns/oa#moderating')
        expect(gm).to include('http://www.w3.org/ns/oa#tagging')
      end
      it 'missing: empty Array' do
        my_tg = OA::Graph.new RDF::Graph.new.from_ttl "
         <https://sul-fedora-dev-a.stanford.edu/fedora/rest/anno/f3bc7da9-d531-4b0c-816a-8f2fc849b0b6> a <http://www.w3.org/ns/oa#Annotation>;
           <http://www.w3.org/ns/oa#hasTarget> <http://searchworks.stanford.edu/view/666> ."
        expect(my_tg.motivated_by).to eq []
      end
    end
    context '#predicate_urls' do
      it 'single' do
        expect(g2.predicate_urls(RDF::Vocab::OA.hasTarget)).to eq ['http://purl.stanford.edu/kq131cs7229']
      end
      it 'multiple' do
        gu = g3.predicate_urls(RDF::Vocab::OA.hasTarget)
        expect(gu.size).to eql 2
        expect(gu).to include('http://purl.stanford.edu/kq131cs7229')
        expect(gu).to include('https://stacks.stanford.edu/image/kq131cs7229/kq131cs7229_05_0032_large.jpg')
      end
      it 'none' do
        expect(g2.predicate_urls(RDF::Vocab::OA.hasBody)).to eq []
      end
      it 'not a url' do
        expect(g1.predicate_urls(RDF::Vocab::OA.hasBody)).to eq []
      end
    end
    context '#body_chars' do
      it 'single' do
        expect(g1.body_chars).to eq ['I love this!']
      end
      it 'multiple' do
        g = OA::Graph.new RDF::Graph.new.from_jsonld '
        {
          "@context": "http://www.w3.org/ns/oa-context-20130208.json",
          "@type": "oa:Annotation",
          "motivatedBy": [
            "oa:tagging"
          ],
          "hasBody": [
            {
              "@type": [
                "cnt:ContentAsText"
              ],
              "chars": "I love this!"
            },
            {
              "@type": [
                "cnt:ContentAsText"
              ],
              "chars": "me too"
            }
          ],
          "hasTarget": "http://purl.stanford.edu/kq131cs7229"
        }'
        gbc = g.body_chars
        expect(gbc.size).to eql 2
        expect(gbc).to include "I love this!"
        expect(gbc).to include "me too"
      end
      it 'multiple bodies, but only one has chars' do
        g = OA::Graph.new RDF::Graph.new.from_jsonld(
          '{
              "@context": "http://www.w3.org/ns/oa-context-20130208.json",
              "@id": "http://example.org/annos/annotation/mult-bodies.json",
              "@type": "oa:Annotation",
              "motivatedBy": [
                "oa:commenting",
                "oa:tagging"
              ],
              "hasBody": [
                {
                  "@type": [
                    "cnt:ContentAsText",
                    "dctypes:Text"
                  ],
                  "chars": "I love this!"
                },
                {
                  "@id": "http://dbpedia.org/resource/Love",
                  "@type": "oa:SemanticTag"
                }
              ],
              "hasTarget": "http://purl.stanford.edu/kq131cs7229"
            }' )
        expect(g.body_chars).to eq ["I love this!"]
      end
      it 'whitespace retained at beginning or ending' do
        g = OA::Graph.new RDF::Graph.new.from_jsonld '
        {
          "@context": "http://www.w3.org/ns/oa-context-20130208.json",
          "@type": "oa:Annotation",
          "motivatedBy": [
            "oa:tagging"
          ],
          "hasBody": [
            {
              "@type": [
                "cnt:ContentAsText"
              ],
              "chars": "  la  "
            }
          ],
          "hasTarget": "http://purl.stanford.edu/kq131cs7229"
        }'
        expect(g.body_chars).to eq ["  la  "]
      end
      it 'chars is empty string' do
        g = OA::Graph.new RDF::Graph.new.from_jsonld '
        {
          "@context": "http://www.w3.org/ns/oa-context-20130208.json",
          "@type": "oa:Annotation",
          "motivatedBy": [
            "oa:tagging"
          ],
          "hasBody": [
            {
              "@type": [
                "cnt:ContentAsText"
              ],
              "chars": ""
            }
          ],
          "hasTarget": "http://purl.stanford.edu/kq131cs7229"
        }'
        expect(g.body_chars).to eq [""]
      end
      it 'body is a url' do
        g = OA::Graph.new RDF::Graph.new.from_jsonld(
          '{
              "@context": "http://www.w3.org/ns/oa-context-20130208.json",
              "@id": "http://example.org/annos/annotation/body-pdf.json",
              "@type": "oa:Annotation",
              "motivatedBy": "oa:commenting",
              "hasBody": {
                "@id": "http://www.example.org/comment.pdf",
                "@type": "dctypes:Text"
              },
              "hasTarget": "http://purl.stanford.edu/kq131cs7229"
            }' )
        expect(g.body_chars).to eq []
      end
    end
    context '#annotated_at' do
      it 'String if present' do
        g = OA::Graph.new RDF::Graph.new.from_jsonld(
          '{
              "@context": "http://www.w3.org/ns/oa-context-20130208.json",
              "@id": "http://example.org/annos/annotation/provenance.json",
              "@type": "oa:Annotation",
              "motivatedBy": "oa:commenting",
              "annotatedAt": "2014-09-03T17:16:13Z",
              "annotatedBy": {
                "@id": "mailto:azaroth42@gmail.com",
                "@type": "foaf:Person",
                "name": "Rob Sanderson"
              },
              "serializedAt": "2014-09-03T17:16:13Z",
              "serializedBy": {
                "@type": "prov:SoftwareAgent",
                "name": "Annotation Factory"
              },
              "hasBody": {
                "@type": [
                  "cnt:ContentAsText",
                  "dctypes:Text"
                ],
                "chars": "I love this!"
              },
              "hasTarget": "http://purl.stanford.edu/kq131cs7229"
            }' )
      end
      it 'nil if absent' do
        expect(g1.annotated_at).to be nil
      end
    end
  end # canned query methods

  context '#remove_non_base_statements' do
    it 'calls #remove_has_target_statements' do
      g = OA::Graph.new(RDF::Graph.new)
      expect(g).to receive(:remove_has_target_statements)
      allow(g).to receive(:remove_has_body_statements)
      g.remove_non_base_statements
    end
    it 'calls #remove_has_body_statements' do
      g = OA::Graph.new(RDF::Graph.new)
      expect(g).to receive(:remove_has_body_statements)
      allow(g).to receive(:remove_has_target_statements).and_return(g)
      g.remove_non_base_statements
    end
  end

  context '#remove_has_body_statements' do
    it 'calls remove_predicate_and_its_object_statements with RDF::Vocab::OA.hasBody' do
      g = OA::Graph.new(RDF::Graph.new)
      expect(g).to receive(:remove_predicate_and_its_object_statements).with(RDF::Vocab::OA.hasBody)
      g.remove_has_body_statements
    end
  end

  context '#remove_has_target_statements' do
    it 'calls remove_predicate_and_its_object_statements with RDF::Vocab::OA.hasTarget' do
      g = OA::Graph.new(RDF::Graph.new)
      expect(g).to receive(:remove_predicate_and_its_object_statements).with(RDF::Vocab::OA.hasTarget)
      g.remove_has_target_statements
    end
  end

  context '#remove_predicate_and_its_object_statements' do
    it 'calls *subject_statements for each object of predicate statement' do
      g = OA::Graph.new(RDF::Graph.new.from_jsonld('{
        "@context": "http://www.w3.org/ns/oa-context-20130208.json",
        "hasTarget": [
          "http://target.one.org",
          "http://target.two.org"
        ]
      }'))
      expect(OA::Graph).to receive(:subject_statements).with(RDF::URI.new("http://target.one.org"), anything)
      expect(OA::Graph).to receive(:subject_statements).with(RDF::URI.new("http://target.two.org"), anything)
      g.remove_predicate_and_its_object_statements(RDF::Vocab::OA.hasTarget)
    end
    it 'removes each predicate statement' do
      rg = RDF::Graph.new.from_jsonld '{
        "@context": "http://www.w3.org/ns/oa-context-20130208.json",
        "@id": "http://some.id.org/666",
        "@type": "oa:Annotation",
        "motivatedBy": "oa:commenting",
        "hasTarget": [
          "http://target.one.org",
          {
            "@id": "http://dbpedia.org/resource/Love",
            "@type": "oa:SemanticTag"
          }
        ]
      }'
      tg = OA::Graph.new rg
      pred_stmts = tg.query([nil, RDF::Vocab::OA.hasTarget, nil])

      pred_stmts.each { |stmt|
        expect(rg).to receive(:delete).with(stmt)
      }
      allow(OA::Graph).to receive(:subject_statements).and_return([])
      tg.remove_predicate_and_its_object_statements(RDF::Vocab::OA.hasTarget)
    end
    it "removes each statement about the predicate statement's object" do
      rg = RDF::Graph.new.from_jsonld '{
        "@context": "http://www.w3.org/ns/oa-context-20130208.json",
        "@id": "http://some.id.org/666",
        "@type": "oa:Annotation",
        "motivatedBy": "oa:commenting",
        "hasTarget": {
          "@type": "oa:SpecificResource",
          "hasSelector": {
            "@type": "oa:FragmentSelector",
            "value": "xywh=0,0,200,200",
            "conformsTo": "http://www.w3.org/TR/media-frags/"
          }
        }
      }'
      tg = OA::Graph.new rg
      expect(tg.size).to eql 8
      pred_stmts = tg.query([nil, RDF::Vocab::OA.hasTarget, nil])
      pred_obj = pred_stmts.first.object
      sub_stmts = OA::Graph.subject_statements(pred_obj, tg)
      expect(sub_stmts.size).to eql 5
      sub_stmts.each { |s|
        expect(rg).to receive(:delete).with(s).and_call_original
      }
      allow(rg).to receive(:delete).with(pred_stmts.first).and_call_original
      tg.remove_predicate_and_its_object_statements(RDF::Vocab::OA.hasTarget)
      expect(tg.size).to eql 2
    end
  end

  context '#make_null_relative_uri_out_of_blank_node' do
    it 'outer blank node becomes null relative uri' do
      g = RDF::Graph.new.from_ttl('[
      a <http://www.w3.org/ns/oa#Annotation>;
      <http://www.w3.org/ns/oa#hasBody> [
        a <http://www.w3.org/2011/content#ContentAsText>,
          <http://purl.org/dc/dcmitype/Text>;
        <http://www.w3.org/2011/content#chars> "I love this!"
        ]
      ] .')
      orig_size = g.size
      anno_stmts = g.query([nil, RDF.type, RDF::Vocab::OA.Annotation])
      expect(anno_stmts.size).to eql 1
      anno_rdf_obj = anno_stmts.first.subject
      expect(anno_rdf_obj).to be_a(RDF::Node)
      g = OA::Graph.new(g)
      g.make_null_relative_uri_out_of_blank_node
      anno_stmts = g.query([nil, RDF.type, RDF::Vocab::OA.Annotation])
      expect(anno_stmts.size).to eql 1
      anno_rdf_obj = anno_stmts.first.subject
      expect(anno_rdf_obj).to be_a(RDF::URI)
      expect(g.size).to eql orig_size
    end
    it 'null relative uri is left alone' do
      g = RDF::Graph.new.from_ttl('<> a <http://www.w3.org/ns/oa#Annotation>;
      <http://www.w3.org/ns/oa#hasBody> [
        a <http://www.w3.org/2011/content#ContentAsText>,
          <http://purl.org/dc/dcmitype/Text>;
        <http://www.w3.org/2011/content#chars> "I love this!"
        ] .')
      orig_size = g.size
      anno_stmts = g.query([nil, RDF.type, RDF::Vocab::OA.Annotation])
      expect(anno_stmts.size).to eql 1
      anno_rdf_obj = anno_stmts.first.subject
      expect(anno_rdf_obj).to be_a(RDF::URI)
      g = OA::Graph.new(g)
      g.make_null_relative_uri_out_of_blank_node
      anno_stmts = g.query([nil, RDF.type, RDF::Vocab::OA.Annotation])
      expect(anno_stmts.size).to eql 1
      anno_rdf_obj = anno_stmts.first.subject
      expect(anno_rdf_obj).to be_a(RDF::URI)
      expect(g.size).to eql orig_size
    end
  end

  context '*subject_statements' do
    it 'returns appropriate blank node statements when the subject is an RDF::Node in the graph' do
      graph = RDF::Graph.new.from_ttl('<http://example.org/annos/annotation/body-chars.ttl> <http://www.w3.org/ns/oa#hasBody> [
           a <http://www.w3.org/2011/content#ContentAsText>,
             <http://purl.org/dc/dcmitype/Text>;
           <http://www.w3.org/2011/content#chars> "I love this!"
         ] .')
      body_resource = graph.query([nil, RDF::Vocab::OA.hasBody, nil]).first.object
      body_stmts = OA::Graph.subject_statements(body_resource, graph)
      expect(body_stmts.size).to eql 3
      expect(body_stmts).to include([body_resource, RDF::Vocab::CNT::chars, 'I love this!'])
      expect(body_stmts).to include([body_resource, RDF.type, RDF::Vocab::CNT.ContentAsText])
      expect(body_stmts).to include([body_resource, RDF.type, RDF::Vocab::DCMIType.Text])
    end
    it 'recurses to get triples from objects of the subject statements' do
      graph = RDF::Graph.new.from_jsonld('{
        "@context": "http://www.w3.org/ns/oa-context-20130208.json",
        "hasTarget": {
          "@type": "oa:SpecificResource",
          "hasSource": "http://purl.stanford.edu/kq131cs7229.html",
          "hasSelector": {
            "@type": "oa:TextPositionSelector",
            "start": 0,
            "end": 66
          }
        }
      }')
      target_resource = graph.query([nil, RDF::Vocab::OA.hasTarget, nil]).first.object
      target_stmts = OA::Graph.subject_statements(target_resource, graph)
      expect(target_stmts.size).to eql 6
      expect(target_stmts).to include([target_resource, RDF.type, RDF::Vocab::OA.SpecificResource])
      expect(target_stmts).to include([target_resource, RDF::Vocab::OA.hasSource, 'http://purl.stanford.edu/kq131cs7229.html'])
      selector_resource =  graph.query([target_resource, RDF::Vocab::OA.hasSelector, nil]).first.object
      expect(target_stmts).to include([target_resource, RDF::Vocab::OA.hasSelector, selector_resource])
      expect(target_stmts).to include([selector_resource, RDF.type, RDF::Vocab::OA.TextPositionSelector])
      expect(target_stmts).to include([selector_resource, RDF::Vocab::OA.start, RDF::Literal.new(0)])
      expect(target_stmts).to include([selector_resource, RDF::Vocab::OA.end, RDF::Literal.new(66)])

      graph = RDF::Graph.new.from_jsonld('{
        "@context": "http://www.w3.org/ns/oa-context-20130208.json",
        "hasTarget": {
          "@type": "oa:SpecificResource",
          "hasSelector": {
            "@type": "oa:FragmentSelector",
            "value": "xywh=0,0,200,200",
            "conformsTo": "http://www.w3.org/TR/media-frags/"
          }
        }
      }')
      target_resource = graph.query([nil, RDF::Vocab::OA.hasTarget, nil]).first.object
      target_stmts = OA::Graph.subject_statements(target_resource, graph)
      expect(target_stmts.size).to eql 5
      expect(target_stmts).to include([target_resource, RDF.type, RDF::Vocab::OA.SpecificResource])
      selector_resource =  graph.query([target_resource, RDF::Vocab::OA.hasSelector, nil]).first.object
      expect(target_stmts).to include([target_resource, RDF::Vocab::OA.hasSelector, selector_resource])
      expect(target_stmts).to include([selector_resource, RDF.type, RDF::Vocab::OA.FragmentSelector])
      expect(target_stmts).to include([selector_resource, RDF.value, RDF::Literal.new('xywh=0,0,200,200')])
      expect(target_stmts).to include([selector_resource, RDF::DC.conformsTo, 'http://www.w3.org/TR/media-frags/'])
    end
    it 'finds all properties of URI nodes' do
      graph = RDF::Graph.new.from_jsonld('{
        "@context": "http://www.w3.org/ns/oa-context-20130208.json",
        "hasTarget": {
          "@type": "oa:SpecificResource",
          "hasSource": {
            "@id": "https://stacks.stanford.edu/image/kq131cs7229/kq131cs7229_05_0032_large.jpg",
            "@type": "dctypes:Image"
          }
        }
      }')
      target_resource = graph.query([nil, RDF::Vocab::OA.hasTarget, nil]).first.object
      target_stmts = OA::Graph.subject_statements(target_resource, graph)
      expect(target_stmts.size).to eql 3
      expect(target_stmts).to include([target_resource, RDF.type, RDF::Vocab::OA.SpecificResource])
      expect(target_stmts).to include([target_resource, RDF::Vocab::OA.hasSource, 'https://stacks.stanford.edu/image/kq131cs7229/kq131cs7229_05_0032_large.jpg'])
      source_resource = graph.query([target_resource, RDF::Vocab::OA.hasSource, nil]).first.object
      expect(target_stmts).to include([target_resource, RDF::Vocab::OA.hasSource, source_resource])
      expect(target_stmts).to include([source_resource, RDF.type, RDF::Vocab::DCMIType.Image])
    end
    it 'empty Array when the subject is not in the graph' do
      graph = RDF::Graph.new.from_ttl('<http://example.org/annos/annotation/body-chars.ttl> <http://www.w3.org/ns/oa#hasBody> [
           a <http://www.w3.org/2011/content#ContentAsText>,
             <http://purl.org/dc/dcmitype/Text>;
           <http://www.w3.org/2011/content#chars> "I love this!"
         ] .')
      expect(OA::Graph.subject_statements(RDF::Node.new, graph)).to eql []
      expect(OA::Graph.subject_statements(RDF::URI.new('http://not.there.org'), graph)).to eql []
    end
    it 'empty Array when the subject is an RDF::URI with no additional properties' do
      graph = RDF::Graph.new.from_ttl('<http://example.org/annos/annotation/body-chars.ttl> <http://www.w3.org/ns/oa#hasTarget> <http://purl.stanford.edu/kq131cs7229>.')
      target_resource = graph.query([nil, RDF::Vocab::OA.hasTarget, nil]).first.object
      expect(target_resource).to be_a RDF::URI
      expect(OA::Graph.subject_statements(target_resource, graph)).to eql []
    end
    it 'empty Array when subject is not RDF::Node or RDF::URI' do
      graph = RDF::Graph.new.from_ttl('<http://example.org/annos/annotation/body-chars.ttl> <http://www.w3.org/ns/oa#hasTarget> <http://purl.stanford.edu/kq131cs7229>.')
      expect(OA::Graph.subject_statements(RDF.type, graph)).to eql []
    end
  end # *subject_statements

  context '*anno_query' do
    it 'should find a solution when graph has RDF.type OA::Annotation' do
      my_url = 'http://fakeurl.org/id'
      g = RDF::Graph.new.from_ttl("<#{my_url}> a <http://www.w3.org/ns/oa#Annotation> .")
      solutions = g.query OA::Graph.anno_query
      expect(solutions.size).to eq 1
      expect(solutions.first.s.to_s).to eq my_url
    end
    it 'should not find a solution when graph has no RDF.type OA::Annotation' do
      g = RDF::Graph.new.from_ttl('<http://anywehre.com> a <http://foo.org/thing> .')
      solutions = g.query OA::Graph.anno_query
      expect(solutions.size).to eq 0
    end
    it "doesn't find solution when graph is empty" do
      solutions = RDF::Graph.new.query OA::Graph.anno_query
      expect(solutions.size).to eq 0
    end
  end

end
